-- ====================================================================
-- TAB: AIM
-- ====================================================================
local ctx = ... or {}
local tabPages           = ctx.tabPages or tabPages
local addSection         = ctx.addSection or addSection
local addToggle          = ctx.addToggle or addToggle
local addButton          = ctx.addButton or addButton
local addSlider          = ctx.addSlider or addSlider
local addInputCard       = ctx.addInputCard or addInputCard
local addCorner          = ctx.addCorner or addCorner
local addStroke          = ctx.addStroke or addStroke
local showNotification   = ctx.showNotification or showNotification
local getSafeGuiParent   = ctx.getSafeGuiParent or getSafeGuiParent
local getEquippedGun     = ctx.getEquippedGun or getEquippedGun
local LocalPlayer        = ctx.LocalPlayer or game:GetService("Players").LocalPlayer
local Camera             = ctx.Camera or workspace.CurrentCamera
local TweenService       = ctx.TweenService or game:GetService("TweenService")
local RunService         = ctx.RunService or game:GetService("RunService")
local UserInputService   = ctx.UserInputService or game:GetService("UserInputService")
local Lighting           = ctx.Lighting or game:GetService("Lighting")
local ReplicatedStorage  = ctx.ReplicatedStorage or game:GetService("ReplicatedStorage")
local ScreenGui          = ctx.ScreenGui or ScreenGui
local MainFrame          = ctx.MainFrame or MainFrame
local particleContainers = ctx.particleContainers or particleContainers
local particlesEnabled   = ctx.particlesEnabled

local AimPage = tabPages["Aim"]
addSection(AimPage, "Waffen Exploits (Game Remotes)")

local function getEquippedGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child:FindFirstChild("GunScript_Server") then
            return child
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") and child:FindFirstChild("GunScript_Server") then
                return child
            end
        end
    end
    return nil
end

local infAmmoEnabled = false
addToggle(AimPage, "Infinite Ammo Loop", "Setzt Mag & Ammo permanent auf 999", false, function(enabled)
    infAmmoEnabled = enabled
    while infAmmoEnabled do
        local gun = getEquippedGun()
        if gun then
            local serverScript = gun:FindFirstChild("GunScript_Server")
            if serverScript then
                local remote = serverScript:FindFirstChild("ChangeMagAndAmmo")
                if remote then
                    pcall(function()
                        remote:FireServer(999, 999)
                    end)
                end
            end
        end
        task.wait(0.5)
    end
end)

addButton(AimPage, "Instant Max Ammo Refill", "Füllt Magazin & Munition sofort voll auf", "Refill", function()
    local gun = getEquippedGun()
    if gun then
        local serverScript = gun:FindFirstChild("GunScript_Server")
        if serverScript then
            local remote = serverScript:FindFirstChild("ChangeMagAndAmmo")
            if remote then
                remote:FireServer(999, 999)
            end
        end
    end
end)

local instantEquip = false
local function applyInstantEquipToTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        tool:SetAttribute("EquipTime", 0)
    end)
    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("NumberValue") or child:IsA("IntValue") or child:IsA("DoubleConstrainedValue") then
            if child.Name == "EquipTime" or child.Name:lower():find("equiptime") then
                pcall(function() child.Value = 0 end)
            end
        end
    end
end

local function hookCharAnimations(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.AnimationPlayed:Connect(function(track)
            if instantEquip then
                local animName = (track.Animation and track.Animation.Name or ""):lower()
                local animId = (track.Animation and track.Animation.AnimationId or ""):lower()
                if animName:find("equip") or animId:find("equip") then
                    pcall(function() track:AdjustSpeed(100) end)
                end
            end
        end)
    end
end

pcall(function()
    if LocalPlayer.Character then
        hookCharAnimations(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        hookCharAnimations(char)
        char.ChildAdded:Connect(function(c)
            if instantEquip and c:IsA("Tool") then
                applyInstantEquipToTool(c)
            end
        end)
    end)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        bp.ChildAdded:Connect(function(c)
            if instantEquip and c:IsA("Tool") then
                applyInstantEquipToTool(c)
            end
        end)
    end
end)

addToggle(AimPage, "Instant Equip (0s Delay)", "Entfernt Waffen-Ziehverzögerung & beschleunigt Waffen-Switch", false, function(enabled)
    instantEquip = enabled
    if instantEquip then
        if LocalPlayer.Character then
            for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
                applyInstantEquipToTool(t)
            end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                applyInstantEquipToTool(t)
            end
        end
    end
end)

addSection(AimPage, "Combat Assistance")

local aimbotEnabled = false
local aimFov = 150
addToggle(AimPage, "Camera Aimbot", "Richtet Kamera auf den nächsten Spieler", false, function(enabled)
    aimbotEnabled = enabled
end)

addSlider(AimPage, "Aimbot FOV Radius", 50, 400, 150, function(val)
    aimFov = val
end)

-- Aimbot Loop
RunService.RenderStepped:Connect(function()
    if not aimbotEnabled then return end
    local closest = nil
    local shortestDist = aimFov

    local mousePos = UserInputService:GetMouseLocation()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = head
                end
            end
        end
    end

    if closest and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
    end
end)

----------------------------------------------------------------------
-- TAB 2 EXTRA: DAVID-STERN CROSSHAIR
----------------------------------------------------------------------
addSection(AimPage, "David-Stern Crosshair")

-- State
local chEnabled    = false
local chColor      = Color3.fromRGB(255, 255, 255)
local chSize       = 40
local chSpin       = false
local chSpinSpeed  = 60   -- deg/sec
local chPulse      = false
local chPulseStr   = 15   -- % of size
local chPulseSpeed = 3    -- oscillations per sec
local chRotation   = 0
local chPulseT     = 0
local chGui        = nil
local chContainer  = nil
local chLineParts  = {}
local chDot        = nil
local chConn       = nil

local function chUpdateColor()
    for _, f in ipairs(chLineParts) do
        f.BackgroundColor3 = chColor
    end
    if chDot then chDot.BackgroundColor3 = chColor end
end

local function chUpdateSize()
    if not chContainer then return end
    local s = chSize * 2
    chContainer.Size = UDim2.new(0, s, 0, s)
    for _, f in ipairs(chLineParts) do
        f.Size = UDim2.new(0, chSize * 2, 0, 2)
    end
end

local function buildCrosshair()
    if chGui then chGui:Destroy() end
    chLineParts = {}

    chGui = Instance.new("ScreenGui")
    chGui.Name     = "WireStarCrosshair"
    chGui.ResetOnSpawn   = false
    chGui.DisplayOrder   = 110
    chGui.IgnoreGuiInset = true
    chGui.Parent = getSafeGuiParent()

    -- Transparent container anchored to screen center
    chContainer = Instance.new("Frame")
    chContainer.Name               = "StarContainer"
    chContainer.BackgroundTransparency = 1
    chContainer.AnchorPoint        = Vector2.new(0.5, 0.5)
    chContainer.Position           = UDim2.new(0.5, 0, 0.5, 0)
    chContainer.Size               = UDim2.new(0, chSize * 2, 0, chSize * 2)
    chContainer.ZIndex             = 10
    chContainer.Parent             = chGui

    -- 3 lines rotated 0 / 60 / 120 deg → 6-pointed star (David-Stern)
    for i = 0, 2 do
        local line = Instance.new("Frame")
        line.AnchorPoint        = Vector2.new(0.5, 0.5)
        line.Position           = UDim2.new(0.5, 0, 0.5, 0)
        line.Size               = UDim2.new(0, chSize * 2, 0, 2)
        line.BackgroundColor3   = chColor
        line.BorderSizePixel    = 0
        line.Rotation           = i * 60
        line.ZIndex             = 10
        line.Parent             = chContainer
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = line

        -- Diamond tips at both ends
        for _, side in ipairs({-1, 1}) do
            local tip = Instance.new("Frame")
            tip.AnchorPoint      = Vector2.new(0.5, 0.5)
            tip.Position         = UDim2.new(0.5 + side * 0.5, 0, 0.5, 0)
            tip.Size             = UDim2.new(0, 5, 0, 5)
            tip.BackgroundColor3 = chColor
            tip.BorderSizePixel  = 0
            tip.Rotation         = 45
            tip.ZIndex           = 11
            tip.Parent           = line
        end

        table.insert(chLineParts, line)
    end

    -- Inner hexagon connector lines (gives the "two triangles" feel)
    -- 6 short diagonal line segments connecting the midpoints
    for i = 0, 5 do
        local seg = Instance.new("Frame")
        seg.AnchorPoint      = Vector2.new(0.5, 0.5)
        seg.BorderSizePixel  = 0
        seg.BackgroundColor3 = chColor
        seg.ZIndex           = 9

        local angle    = math.rad(i * 60)
        local nextAngle = math.rad((i + 1) * 60)
        local r        = chSize * 0.5  -- inner ring radius

        local x1 = math.cos(angle)    * r
        local y1 = math.sin(angle)    * r
        local x2 = math.cos(nextAngle)* r
        local y2 = math.sin(nextAngle)* r

        local dx = x2 - x1
        local dy = y2 - y1
        local len = math.sqrt(dx*dx + dy*dy)
        local midX = (x1 + x2) / 2
        local midY = (y1 + y2) / 2
        local rot  = math.deg(math.atan2(dy, dx))

        seg.Size     = UDim2.new(0, len, 0, 1)
        seg.Position = UDim2.new(0.5, midX - len/2, 0.5, midY)
        seg.Rotation = rot
        seg.Parent   = chContainer

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(1, 0)
        sc.Parent = seg
        table.insert(chLineParts, seg)
    end

    -- Center dot
    chDot = Instance.new("Frame")
    chDot.AnchorPoint      = Vector2.new(0.5, 0.5)
    chDot.Position         = UDim2.new(0.5, 0, 0.5, 0)
    chDot.Size             = UDim2.new(0, 5, 0, 5)
    chDot.BackgroundColor3 = chColor
    chDot.BorderSizePixel  = 0
    chDot.ZIndex           = 12
    chDot.Parent           = chContainer
    local dc = Instance.new("UICorner")
    dc.CornerRadius = UDim.new(1, 0)
    dc.Parent = chDot
end

local function startCrosshairLoop()
    if chConn then chConn:Disconnect() end
    chConn = RunService.RenderStepped:Connect(function(dt)
        if not chContainer or not chContainer.Parent then return end

        if chSpin then
            chRotation = (chRotation + chSpinSpeed * dt) % 360
            chContainer.Rotation = chRotation
        end

        if chPulse then
            chPulseT = chPulseT + dt * chPulseSpeed
            local pulse = 1 + math.sin(chPulseT * math.pi * 2) * (chPulseStr / 100)
            local s = chSize * 2 * pulse
            chContainer.Size = UDim2.new(0, s, 0, s)
            for _, f in ipairs(chLineParts) do
                if f.Size.Y.Offset >= 1 and f.Size.Y.Offset <= 2 then
                    f.Size = UDim2.new(0, chSize * 2 * pulse, 0, 2)
                end
            end
        end
    end)
end

-- Toggle Enable
addToggle(AimPage, "David-Stern Crosshair", "Zeigt einen animierten David-Stern als Fadenkreuz an", false, function(enabled)
    chEnabled = enabled
    if enabled then
        buildCrosshair()
        startCrosshairLoop()
    else
        if chConn then chConn:Disconnect(); chConn = nil end
        if chGui then chGui:Destroy(); chGui = nil end
        chContainer = nil; chLineParts = {}; chDot = nil
    end
end)

-- Color presets row
local colorCard = Instance.new("Frame")
colorCard.Name = "ColorCard"
colorCard.Size = UDim2.new(1, 0, 0, 52)
colorCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
colorCard.BackgroundTransparency = 0.97
colorCard.BorderSizePixel = 0
colorCard.ZIndex = 4
colorCard.Parent = AimPage
addCorner(colorCard, 8)
addStroke(colorCard, Color3.fromRGB(255, 255, 255), 1, 0.94)

local colorTitle = Instance.new("TextLabel")
colorTitle.BackgroundTransparency = 1
colorTitle.Position = UDim2.new(0, 12, 0, 4)
colorTitle.Size = UDim2.new(1, -12, 0, 14)
colorTitle.Font = Enum.Font.GothamMedium
colorTitle.Text = "Farbe"
colorTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
colorTitle.TextSize = 11
colorTitle.TextXAlignment = Enum.TextXAlignment.Left
colorTitle.ZIndex = 5
colorTitle.Parent = colorCard

local colorPresets = {
    { name = "Weiß",  col = Color3.fromRGB(255,255,255) },
    { name = "Rot",   col = Color3.fromRGB(255, 60, 60) },
    { name = "Cyan",  col = Color3.fromRGB(0, 220, 255) },
    { name = "Grün",  col = Color3.fromRGB(60, 255, 120) },
    { name = "Gelb",  col = Color3.fromRGB(255, 220, 0) },
    { name = "Lila",  col = Color3.fromRGB(180, 60, 255) },
}

local colorRow = Instance.new("Frame")
colorRow.BackgroundTransparency = 1
colorRow.Position = UDim2.new(0, 10, 0, 22)
colorRow.Size = UDim2.new(1, -20, 0, 22)
colorRow.ZIndex = 5
colorRow.Parent = colorCard

local colorLayout = Instance.new("UIListLayout")
colorLayout.FillDirection = Enum.FillDirection.Horizontal
colorLayout.Padding = UDim.new(0, 5)
colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
colorLayout.Parent = colorRow

for ci, preset in ipairs(colorPresets) do
    local swatch = Instance.new("TextButton")
    swatch.Size = UDim2.new(0, 32, 0, 18)
    swatch.BackgroundColor3 = preset.col
    swatch.BackgroundTransparency = 0.15
    swatch.BorderSizePixel = 0
    swatch.Text = preset.name
    swatch.Font = Enum.Font.Gotham
    swatch.TextSize = 7
    swatch.TextColor3 = Color3.fromRGB(0, 0, 0)
    swatch.AutoButtonColor = false
    swatch.ZIndex = 6
    swatch.LayoutOrder = ci
    swatch.Parent = colorRow
    addCorner(swatch, 4)

    swatch.MouseButton1Click:Connect(function()
        chColor = preset.col
        chUpdateColor()
        -- Pulse the swatch
        TweenService:Create(swatch, TweenInfo.new(0.12), {
            BackgroundTransparency = 0
        }):Play()
        task.delay(0.12, function()
            TweenService:Create(swatch, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.15
            }):Play()
        end)
    end)
end

-- Size slider
addSlider(AimPage, "Groesse (Size)", 10, 120, 40, function(val)
    chSize = val
    if chContainer then chUpdateSize() end
end)

-- Spin section
addToggle(AimPage, "Rotation (Dreht sich)", "Lässt den Stern kontinuierlich rotieren", false, function(enabled)
    chSpin = enabled
    if not chSpin and chContainer then
        chRotation = 0
        chContainer.Rotation = 0
    end
end)

addSlider(AimPage, "Rotationsgeschwindigkeit", 5, 360, 60, function(val)
    chSpinSpeed = val
end)

-- Pulse section
addToggle(AimPage, "Pulsieren (Atmet)", "Lässt den Stern ein- und ausatmen", false, function(enabled)
    chPulse = enabled
    if not chPulse and chContainer then
        chPulseT = 0
        chUpdateSize()
    end
end)

addSlider(AimPage, "Pulsstaerke (%)", 5, 60, 15, function(val)
    chPulseStr = val
end)

addSlider(AimPage, "Pulsgeschwindigkeit", 1, 10, 3, function(val)
    chPulseSpeed = val
end)

----------------------------------------------------------------------
-- TAB 2: COMBAT & GUN MODDER (aus --settings--.txt, --stab handler--, --Ragdoll fix--, --shot blocker--)
----------------------------------------------------------------------
addSection(AimPage, "Combat & Gun Modder")

local noJamming = false
local function applyGunMods(tool)
    if not tool or not tool:IsA("Tool") then return end
    pcall(function()
        local settingModule = tool:FindFirstChild("Setting")
        if settingModule and settingModule:IsA("ModuleScript") then
            local settingTable = require(settingModule)
            if typeof(settingTable) == "table" and noJamming then
                settingTable.JamChance = 0
            end
        end
    end)
end

addToggle(AimPage, "No Weapon Jamming", "Verhindert Ladehemmungen bei allen Schusswaffen (JamChance = 0)", false, function(enabled)
    noJamming = enabled
    if noJamming then
        local char = LocalPlayer.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do applyGunMods(item) end
        end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, item in ipairs(bp:GetChildren()) do applyGunMods(item) end
        end
    end
end)

local rapidFireMod = false
addToggle(AimPage, "Rapid Fire & Full Auto Mod", "Erhöht Feuerrate und schaltet Vollautomatik frei", false, function(enabled)
    rapidFireMod = enabled
    while rapidFireMod do
        pcall(function()
            local gun = getEquippedGun()
            if gun then
                local setting = gun:FindFirstChild("Setting")
                if setting and setting:IsA("ModuleScript") then
                    local sTab = require(setting)
                    if typeof(sTab) == "table" then
                        sTab.Auto = true
                        sTab.FireRate = 0.05
                        sTab.SpreadX = 0
                        sTab.SpreadY = 0
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

local keepToolsRagdoll = false
local ragdollFixConn = nil
addToggle(AimPage, "Keep Tools on Ragdoll", "Verhindert, dass Waffen beim Stürzen/Umfallen weggesteckt werden", false, function(enabled)
    keepToolsRagdoll = enabled
    if keepToolsRagdoll then
        local function cleanRagdollFix(char)
            if not char then return end
            local fix = char:FindFirstChild("RAGDOLL FIX")
            if fix then fix:Destroy() end
        end
        cleanRagdollFix(LocalPlayer.Character)
        ragdollFixConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            cleanRagdollFix(char)
        end)
    else
        if ragdollFixConn then
            ragdollFixConn:Disconnect()
            ragdollFixConn = nil
        end
    end
end)

local antiKnifeStun = false
addToggle(AimPage, "Anti-Knife (Auto-Remove)", "Entfernt Messer sofort, wenn man erstochen wird (kein 3s E-Halten)", false, function(enabled)
    antiKnifeStun = enabled
    while antiKnifeStun do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local stabHandler = char:FindFirstChild("StabHandler")
                local remoteFunc = stabHandler and stabHandler:FindFirstChild("RemoteFunction")
                if remoteFunc then
                    remoteFunc:InvokeServer()
                end
                local knifeDecoy = char:FindFirstChild("KnifeDecoy")
                if knifeDecoy then
                    local prompt = knifeDecoy:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        fireproximityprompt(prompt, 0)
                    end
                end
            end
        end)
        task.wait(0.3)
    end
end)

local antiFistSlow = false
addToggle(AimPage, "Anti-Fist Slowdown (Anti-Stun)", "Verhindert, dass Schläge deine Laufgeschwindigkeit auf 6 drosseln", false, function(enabled)
    antiFistSlow = enabled
    while antiFistSlow do
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and hum.WalkSpeed < 16 and hum.WalkSpeed > 0 then
                hum.WalkSpeed = 16
            end
        end)
        task.wait(0.1)
    end
end)

addButton(AimPage, "Attach Shoot Blocker Part", "Erstellt einen Schussblocker am Torso (aus ShootBlocker)", "Attach", function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local existing = char:FindFirstChild("ShootBlocker")
        if existing then existing:Destroy() end
        local part = Instance.new("Part")
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Transparency = 1
        part.Anchored = false
        part.Size = Vector3.new(0.3, 0.3, 0.3)
        part.Name = "ShootBlocker"
        local weld = Instance.new("Weld")
        weld.Part0 = part
        weld.Part1 = hrp
        weld.C0 = CFrame.new(Vector3.new(0, -1, 2.2))
        weld.Parent = part
        part.Parent = char
    end
end)

----------------------------------------------------------------------
-- TAB: TELEPORT (Aus --teleport locations--.txt & Map Targets)
