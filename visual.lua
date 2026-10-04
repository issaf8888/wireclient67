-- ====================================================================
-- TAB: VISUELL
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

local VisualPage = tabPages["Visuell"]
addSection(VisualPage, "Ambient Lighting Changer")

-- Original Lighting Settings speichern
local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origClockTime = Lighting.ClockTime

local function setAmbientColor(col)
    Lighting.Ambient = col
    Lighting.OutdoorAmbient = col
end

-- Farbkarten für Ambient Presets
local ambientCard = Instance.new("Frame")
ambientCard.Name = "AmbientPresetCard"
ambientCard.Size = UDim2.new(1, 0, 0, 72)
ambientCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ambientCard.BackgroundTransparency = 0.97
ambientCard.BorderSizePixel = 0
ambientCard.ZIndex = 4
ambientCard.Parent = VisualPage
addCorner(ambientCard, 8)
addStroke(ambientCard, Color3.fromRGB(255, 255, 255), 1, 0.94)

local ambTitle = Instance.new("TextLabel")
ambTitle.BackgroundTransparency = 1
ambTitle.Position = UDim2.new(0, 12, 0, 8)
ambTitle.Size = UDim2.new(1, -24, 0, 16)
ambTitle.Font = Enum.Font.GothamMedium
ambTitle.Text = "Ambient Color Presets"
ambTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
ambTitle.TextSize = 12
ambTitle.TextXAlignment = Enum.TextXAlignment.Left
ambTitle.ZIndex = 5
ambTitle.Parent = ambientCard

local presetContainer = Instance.new("Frame")
presetContainer.BackgroundTransparency = 1
presetContainer.Position = UDim2.new(0, 12, 0, 32)
presetContainer.Size = UDim2.new(1, -24, 0, 28)
presetContainer.ZIndex = 5
presetContainer.Parent = ambientCard

local pList = Instance.new("UIListLayout")
pList.FillDirection = Enum.FillDirection.Horizontal
pList.Padding = UDim.new(0, 6)
pList.Parent = presetContainer

local presets = {
    { name = "White",   color = Color3.fromRGB(255, 255, 255) },
    { name = "Purple",  color = Color3.fromRGB(160, 50, 240) },
    { name = "Cyan",    color = Color3.fromRGB(40, 200, 240) },
    { name = "Red",     color = Color3.fromRGB(230, 40, 40) },
    { name = "Green",   color = Color3.fromRGB(40, 230, 90) },
    { name = "Reset",   color = origAmbient }
}

for _, p in ipairs(presets) do
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 58, 1, 0)
    pBtn.BackgroundColor3 = p.color
    pBtn.BackgroundTransparency = (p.name == "Reset") and 0.85 or 0.25
    pBtn.Font = Enum.Font.GothamMedium
    pBtn.Text = p.name
    pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    pBtn.TextSize = 10
    pBtn.AutoButtonColor = false
    pBtn.ZIndex = 6
    pBtn.Parent = presetContainer
    addCorner(pBtn, 6)
    addStroke(pBtn, Color3.fromRGB(255, 255, 255), 1, 0.7)

    pBtn.MouseButton1Click:Connect(function()
        setAmbientColor(p.color)
    end)
end

addSlider(VisualPage, "World Brightness", 0, 8, math.floor(origBrightness or 2), function(val)
    Lighting.Brightness = val
end)

addSlider(VisualPage, "Time of Day (ClockTime)", 0, 24, math.floor(origClockTime or 14), function(val)
    Lighting.ClockTime = val
end)

addToggle(VisualPage, "Remove Fog", "Entfernt Nebel komplett aus der Welt", false, function(enabled)
    if enabled then
        Lighting.FogEnd = 999999
    else
        Lighting.FogEnd = 1000
    end
end)

addSection(VisualPage, "Player ESP")

-- ------------------------------------------------------------------
-- ADVANCED ESP SYSTEM (Corner Box, Health, Name, Distance)
-- ------------------------------------------------------------------
local espEnabled        = false
local espShowBox        = true
local espShowHealth     = true
local espShowName       = true
local espShowDistance   = true
local espBoxColor       = Color3.fromRGB(255, 255, 255)
local espTextColor      = Color3.fromRGB(255, 255, 255)
local espHealthColor    = Color3.fromRGB(80, 255, 120)

local espDrawings       = {}   -- { player = p, drawings = {...} }
local espRenderConn     = nil

-- Hilfsfunktion: 3D → 2D Bildschirmkoordinaten
local function worldToScreen(pos)
    local cam = workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), screenPos.Z, onScreen
end

-- Zeichne 4 Ecken einer Box (Corner-Box-Stil)
local function makeCornerBox(parent)
    local corners = {}
    local CL = 6  -- Länge der Ecken-Linien
    -- Jede Ecke: 2 Linien (horizontal + vertikal)
    for i = 1, 4 do
        local lH = Instance.new("Frame")
        lH.BackgroundColor3 = espBoxColor
        lH.BorderSizePixel  = 0
        lH.ZIndex            = 12
        lH.Parent            = parent

        local lV = Instance.new("Frame")
        lV.BackgroundColor3 = espBoxColor
        lV.BorderSizePixel  = 0
        lV.ZIndex            = 12
        lV.Parent            = parent

        corners[i] = { h = lH, v = lV }
    end
    return corners
end

local function updateCornerBox(corners, x, y, w, h, color, thickness)
    thickness = thickness or 1.5
    local CL = math.clamp(math.min(w, h) * 0.2, 4, 10)
    local configs = {
        -- Top-Left
        { hx = x,         hy = y,         hw = CL,       hh = thickness, vx = x,         vy = y,         vw = thickness, vh = CL },
        -- Top-Right
        { hx = x+w-CL,    hy = y,         hw = CL,       hh = thickness, vx = x+w-thickness, vy = y,     vw = thickness, vh = CL },
        -- Bottom-Left
        { hx = x,         hy = y+h-thickness, hw = CL,   hh = thickness, vx = x,         vy = y+h-CL,   vw = thickness, vh = CL },
        -- Bottom-Right
        { hx = x+w-CL,    hy = y+h-thickness, hw = CL,   hh = thickness, vx = x+w-thickness, vy = y+h-CL, vw = thickness, vh = CL },
    }
    for i, cfg in ipairs(configs) do
        corners[i].h.Position = UDim2.new(0, cfg.hx, 0, cfg.hy)
        corners[i].h.Size     = UDim2.new(0, cfg.hw, 0, cfg.hh)
        corners[i].h.BackgroundColor3 = color
        corners[i].h.Visible  = true

        corners[i].v.Position = UDim2.new(0, cfg.vx, 0, cfg.vy)
        corners[i].v.Size     = UDim2.new(0, cfg.vw, 0, cfg.vh)
        corners[i].v.BackgroundColor3 = color
        corners[i].v.Visible  = true
    end
end

local function hideCornerBox(corners)
    for _, c in ipairs(corners) do
        c.h.Visible = false
        c.v.Visible = false
    end
end

-- ESP-Container über ScreenGui
local ESPCanvas = Instance.new("Frame")
ESPCanvas.Name              = "ESPCanvas"
ESPCanvas.BackgroundTransparency = 1
ESPCanvas.Size              = UDim2.new(1, 0, 1, 0)
ESPCanvas.Position          = UDim2.new(0, 0, 0, 0)
ESPCanvas.ZIndex            = 10
ESPCanvas.Parent            = ScreenGui

local function createEspDrawings(p)
    if p == LocalPlayer then return end
    if espDrawings[p] then return end

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size     = UDim2.new(1, 0, 1, 0)
    container.ZIndex   = 10
    container.Visible  = false
    container.Parent   = ESPCanvas

    -- Corner Box (8 Linien für 4 Ecken)
    local corners = makeCornerBox(container)

    -- Health Bar (links von der Box)
    local healthBar = Instance.new("Frame")
    healthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    healthBar.BackgroundTransparency = 0.3
    healthBar.BorderSizePixel  = 0
    healthBar.ZIndex            = 11
    healthBar.Parent            = container

    local healthFill = Instance.new("Frame")
    healthFill.BackgroundColor3 = espHealthColor
    healthFill.BorderSizePixel  = 0
    healthFill.ZIndex            = 12
    healthFill.AnchorPoint      = Vector2.new(0, 1)
    healthFill.Parent            = healthBar

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextColor3         = espTextColor
    nameLabel.TextSize           = 11
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3   = Color3.new(0,0,0)
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Center
    nameLabel.ZIndex             = 13
    nameLabel.Parent             = container

    -- Distance Label
    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Font               = Enum.Font.Gotham
    distLabel.TextColor3         = Color3.fromRGB(200, 200, 200)
    distLabel.TextSize           = 10
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3   = Color3.new(0,0,0)
    distLabel.TextXAlignment     = Enum.TextXAlignment.Center
    distLabel.ZIndex             = 13
    distLabel.Parent             = container

    espDrawings[p] = {
        container  = container,
        corners    = corners,
        healthBar  = healthBar,
        healthFill = healthFill,
        nameLabel  = nameLabel,
        distLabel  = distLabel,
    }
end

local function removeEspDrawings(p)
    if espDrawings[p] then
        pcall(function() espDrawings[p].container:Destroy() end)
        espDrawings[p] = nil
    end
end

-- Für alle Spieler erstellen
for _, p in ipairs(Players:GetPlayers()) do
    createEspDrawings(p)
end
Players.PlayerAdded:Connect(function(p)
    createEspDrawings(p)
end)
Players.PlayerRemoving:Connect(function(p)
    removeEspDrawings(p)
end)

-- Update-Loop
local function startEspLoop()
    if espRenderConn then return end
    espRenderConn = RunService.RenderStepped:Connect(function()
        if not espEnabled then
            for _, d in pairs(espDrawings) do
                if d and d.container then
                    d.container.Visible = false
                end
            end
            return
        end

        local cam      = workspace.CurrentCamera
        local vp       = cam.ViewportSize
        local myChar   = LocalPlayer.Character
        local myHRP    = myChar and myChar:FindFirstChild("HumanoidRootPart")

        for p, d in pairs(espDrawings) do
            if d and d.container and d.container.Parent then
                local char = p.Character
                local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                local hum  = char and char:FindFirstChild("Humanoid")

                if char and hrp and hum then
                    -- Distanz berechnen
                    local dist = myHRP and (myHRP.Position - hrp.Position).Magnitude or 0

                    -- 3D → 2D Bounding Box approximieren
                    local headPos = hrp.Position + Vector3.new(0, 2.5, 0)
                    local feetPos = hrp.Position - Vector3.new(0, 3.0, 0)

                    local topScreen, topDepth, topOn = worldToScreen(headPos)
                    local botScreen, botDepth, botOn = worldToScreen(feetPos)

                    if topOn and topDepth > 0 then
                        d.container.Visible = true

                        -- Box Dimensionen
                        local boxH = math.abs(topScreen.Y - botScreen.Y)
                        local boxW = boxH * 0.55
                        local bx   = topScreen.X - boxW * 0.5
                        local by   = topScreen.Y
                        local bw   = boxW
                        local bh   = boxH

                        -- Corner Box
                        if espShowBox then
                            updateCornerBox(d.corners, bx, by, bw, bh, espBoxColor)
                        else
                            hideCornerBox(d.corners)
                        end

                        -- Health Bar (links, 3px breit)
                        if espShowHealth then
                            local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local barX    = bx - 6
                            local barY    = by
                            local barH    = bh
                            local barW    = 3

                            -- Farbe: Grün → Gelb → Rot
                            local hpColor
                            if hpRatio > 0.5 then
                                hpColor = Color3.fromRGB(
                                    math.floor(255 * (1 - hpRatio) * 2),
                                    255, 60
                                )
                            else
                                hpColor = Color3.fromRGB(
                                    255,
                                    math.floor(255 * hpRatio * 2),
                                    60
                                )
                            end

                            d.healthBar.Position          = UDim2.new(0, barX, 0, barY)
                            d.healthBar.Size              = UDim2.new(0, barW, 0, barH)
                            d.healthBar.Visible           = true
                            d.healthFill.Size             = UDim2.new(1, 0, hpRatio, 0)
                            d.healthFill.Position         = UDim2.new(0, 0, 1 - hpRatio, 0)
                            d.healthFill.BackgroundColor3 = hpColor
                            d.healthFill.Visible          = true
                        else
                            d.healthBar.Visible  = false
                            d.healthFill.Visible = false
                        end

                        -- Name Label (über der Box)
                        if espShowName then
                            d.nameLabel.Text       = p.DisplayName ~= "" and p.DisplayName or p.Name
                            d.nameLabel.TextColor3 = espTextColor
                            d.nameLabel.Position   = UDim2.new(0, bx - 30, 0, by - 16)
                            d.nameLabel.Size       = UDim2.new(0, bw + 60, 0, 14)
                            d.nameLabel.Visible    = true
                        else
                            d.nameLabel.Visible = false
                        end

                        -- Distance Label (unter der Box)
                        if espShowDistance then
                            local distStr        = string.format("[%.0fm]", dist)
                            d.distLabel.Text     = distStr
                            d.distLabel.Position = UDim2.new(0, bx - 20, 0, by + bh + 2)
                            d.distLabel.Size     = UDim2.new(0, bw + 40, 0, 13)
                            d.distLabel.Visible  = true
                        else
                            d.distLabel.Visible = false
                        end
                    else
                        d.container.Visible = false
                    end
                else
                    d.container.Visible = false
                end
            else
                espDrawings[p] = nil
            end
        end
    end)
end

startEspLoop()

-- ── ESP Preview Panel ───────────────────────────────────────────────
-- Zeigt eine Vorschau der ESP-Box direkt im Tab

local previewCard = Instance.new("Frame")
previewCard.Name = "ESPPreviewCard"
previewCard.Size = UDim2.new(1, 0, 0, 130)
previewCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
previewCard.BackgroundTransparency = 0.97
previewCard.BorderSizePixel = 0
previewCard.ZIndex = 4
previewCard.Parent = VisualPage
addCorner(previewCard, 8)
addStroke(previewCard, Color3.fromRGB(255, 255, 255), 1, 0.94)

local previewTitle = Instance.new("TextLabel")
previewTitle.BackgroundTransparency = 1
previewTitle.Position = UDim2.new(0, 12, 0, 8)
previewTitle.Size = UDim2.new(0.5, -16, 0, 14)
previewTitle.Font = Enum.Font.GothamMedium
previewTitle.Text = "ESP VORSCHAU"
previewTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
previewTitle.TextSize = 10
previewTitle.TextXAlignment = Enum.TextXAlignment.Left
previewTitle.ZIndex = 5
previewTitle.Parent = previewCard

-- Preview-Canvas
local previewCanvas = Instance.new("Frame")
previewCanvas.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
previewCanvas.BackgroundTransparency = 0.4
previewCanvas.Position = UDim2.new(0.5, -50, 0, 26)
previewCanvas.Size = UDim2.new(0, 100, 0, 95)
previewCanvas.ZIndex = 5
previewCanvas.ClipsDescendants = true
previewCanvas.Parent = previewCard
addCorner(previewCanvas, 4)
addStroke(previewCanvas, Color3.fromRGB(255, 255, 255), 1, 0.9)

-- Fake "Charakter-Silhouette" im Preview
local silhouette = Instance.new("Frame")
silhouette.AnchorPoint = Vector2.new(0.5, 1)
silhouette.Position = UDim2.new(0.5, 0, 0.94, 0)
silhouette.Size = UDim2.new(0, 18, 0, 42)
silhouette.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
silhouette.BackgroundTransparency = 0.85
silhouette.BorderSizePixel = 0
silhouette.ZIndex = 6
silhouette.Parent = previewCanvas
addCorner(silhouette, 3)

-- Kopf Kreis
local head = Instance.new("Frame")
head.AnchorPoint = Vector2.new(0.5, 1)
head.Position = UDim2.new(0.5, 0, 0.06, 12)
head.Size = UDim2.new(0, 14, 0, 14)
head.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
head.BackgroundTransparency = 0.82
head.BorderSizePixel = 0
head.ZIndex = 6
head.Parent = previewCanvas
addCorner(head, 7)

-- Preview: Corner Box Lines (statisch)
local function makePreviewLine(parent, px, py, pw, ph, col)
    local l = Instance.new("Frame")
    l.BackgroundColor3 = col or Color3.fromRGB(255, 255, 255)
    l.BorderSizePixel = 0
    l.ZIndex = 7
    l.Position = UDim2.new(0, px, 0, py)
    l.Size = UDim2.new(0, pw, 0, ph)
    l.Parent = parent
    return l
end

-- Preview-Farb-Update-Funktion
local previewLines = {}
local previewNameLbl = nil
local previewDistLbl = nil
local previewHpBar   = nil
local previewHpFill  = nil

local function rebuildPreview()
    -- Lösche alte Linien
    for _, l in ipairs(previewLines) do pcall(function() l:Destroy() end) end
    previewLines = {}

    if previewNameLbl then pcall(function() previewNameLbl:Destroy() end) end
    if previewDistLbl then pcall(function() previewDistLbl:Destroy() end) end
    if previewHpBar   then pcall(function() previewHpBar:Destroy()   end) end
    if previewHpFill  then pcall(function() previewHpFill:Destroy()  end) end

    -- Box bounds innerhalb previewCanvas (Offset-Koordinaten)
    local BX, BY, BW, BH = 19, 3, 62, 58
    local CL = 9  -- Ecken-Länge
    local TH = 1.5 -- Thickness

    -- 4 Ecken × 2 Linien
    local boxDef = {
        -- TL
        {BX,        BY,        CL, TH},
        {BX,        BY,        TH, CL},
        -- TR
        {BX+BW-CL,  BY,        CL, TH},
        {BX+BW-TH,  BY,        TH, CL},
        -- BL
        {BX,        BY+BH-TH,  CL, TH},
        {BX,        BY+BH-CL,  TH, CL},
        -- BR
        {BX+BW-CL,  BY+BH-TH,  CL, TH},
        {BX+BW-TH,  BY+BH-CL,  TH, CL},
    }

    if espShowBox then
        for _, d in ipairs(boxDef) do
            local l = makePreviewLine(previewCanvas, d[1], d[2], d[3], d[4], espBoxColor)
            table.insert(previewLines, l)
        end
    end

    -- HP Bar links
    if espShowHealth then
        previewHpBar = Instance.new("Frame")
        previewHpBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        previewHpBar.BackgroundTransparency = 0.3
        previewHpBar.BorderSizePixel = 0
        previewHpBar.ZIndex = 7
        previewHpBar.Position = UDim2.new(0, BX - 5, 0, BY)
        previewHpBar.Size = UDim2.new(0, 3, 0, BH)
        previewHpBar.Parent = previewCanvas

        previewHpFill = Instance.new("Frame")
        previewHpFill.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
        previewHpFill.BorderSizePixel = 0
        previewHpFill.ZIndex = 8
        previewHpFill.AnchorPoint = Vector2.new(0, 1)
        previewHpFill.Position = UDim2.new(0, 0, 1, 0)
        previewHpFill.Size = UDim2.new(1, 0, 0.75, 0)
        previewHpFill.Parent = previewHpBar
    end

    -- Name
    if espShowName then
        previewNameLbl = Instance.new("TextLabel")
        previewNameLbl.BackgroundTransparency = 1
        previewNameLbl.Font = Enum.Font.GothamBold
        previewNameLbl.TextColor3 = espTextColor
        previewNameLbl.TextSize = 9
        previewNameLbl.TextStrokeTransparency = 0.2
        previewNameLbl.TextStrokeColor3 = Color3.new(0,0,0)
        previewNameLbl.Text = "PlayerName"
        previewNameLbl.Position = UDim2.new(0, BX - 8, 0, BY - 13)
        previewNameLbl.Size = UDim2.new(0, BW + 16, 0, 12)
        previewNameLbl.TextXAlignment = Enum.TextXAlignment.Center
        previewNameLbl.ZIndex = 8
        previewNameLbl.Parent = previewCanvas
    end

    -- Distance
    if espShowDistance then
        previewDistLbl = Instance.new("TextLabel")
        previewDistLbl.BackgroundTransparency = 1
        previewDistLbl.Font = Enum.Font.Gotham
        previewDistLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        previewDistLbl.TextSize = 8
        previewDistLbl.TextStrokeTransparency = 0.2
        previewDistLbl.TextStrokeColor3 = Color3.new(0,0,0)
        previewDistLbl.Text = "[42m]"
        previewDistLbl.Position = UDim2.new(0, BX - 8, 0, BY + BH + 1)
        previewDistLbl.Size = UDim2.new(0, BW + 16, 0, 11)
        previewDistLbl.TextXAlignment = Enum.TextXAlignment.Center
        previewDistLbl.ZIndex = 8
        previewDistLbl.Parent = previewCanvas
    end
end

rebuildPreview()

-- ── ESP Toggle Controls ──────────────────────────────────────────────

addToggle(VisualPage, "ESP Aktivieren", "Zeigt allen Spielern Corner Box, Health, Name & Distanz", false, function(enabled)
    espEnabled = enabled
    if not enabled then
        for _, d in pairs(espDrawings) do
            if d and d.container then d.container.Visible = false end
        end
    end
end)

addToggle(VisualPage, "ESP Corner Box", "Zeigt 2D Ecken-Box um Spieler", true, function(enabled)
    espShowBox = enabled
    rebuildPreview()
end)

addToggle(VisualPage, "ESP Health Bar", "Zeigt Health Bar links neben der Box", true, function(enabled)
    espShowHealth = enabled
    rebuildPreview()
end)

addToggle(VisualPage, "ESP Name", "Zeigt Spieler-Namen über der Box", true, function(enabled)
    espShowName = enabled
    rebuildPreview()
end)

addToggle(VisualPage, "ESP Distanz", "Zeigt Entfernung in Metern unter der Box", true, function(enabled)
    espShowDistance = enabled
    rebuildPreview()
end)

-- ESP Farben
addSection(VisualPage, "ESP Farben")

-- Box Farben
local espBoxColorCard = Instance.new("Frame")
espBoxColorCard.Name = "ESPBoxColorCard"
espBoxColorCard.Size = UDim2.new(1, 0, 0, 52)
espBoxColorCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
espBoxColorCard.BackgroundTransparency = 0.97
espBoxColorCard.BorderSizePixel = 0
espBoxColorCard.ZIndex = 4
espBoxColorCard.Parent = VisualPage
addCorner(espBoxColorCard, 8)
addStroke(espBoxColorCard, Color3.fromRGB(255, 255, 255), 1, 0.94)

local espBoxColorTitle = Instance.new("TextLabel")
espBoxColorTitle.BackgroundTransparency = 1
espBoxColorTitle.Position = UDim2.new(0, 12, 0, 7)
espBoxColorTitle.Size = UDim2.new(1, -24, 0, 14)
espBoxColorTitle.Font = Enum.Font.GothamMedium
espBoxColorTitle.Text = "Box Farbe"
espBoxColorTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
espBoxColorTitle.TextSize = 11
espBoxColorTitle.TextXAlignment = Enum.TextXAlignment.Left
espBoxColorTitle.ZIndex = 5
espBoxColorTitle.Parent = espBoxColorCard

local espBoxColorRow = Instance.new("Frame")
espBoxColorRow.BackgroundTransparency = 1
espBoxColorRow.Position = UDim2.new(0, 10, 0, 26)
espBoxColorRow.Size = UDim2.new(1, -20, 0, 20)
espBoxColorRow.ZIndex = 5
espBoxColorRow.Parent = espBoxColorCard

local espBcLayout = Instance.new("UIListLayout")
espBcLayout.FillDirection = Enum.FillDirection.Horizontal
espBcLayout.Padding = UDim.new(0, 5)
espBcLayout.Parent = espBoxColorRow

local espBoxColPresets = {
    { name="Weiß",   col=Color3.fromRGB(255,255,255) },
    { name="Cyan",   col=Color3.fromRGB(0,220,255)   },
    { name="Grün",   col=Color3.fromRGB(60,255,120)  },
    { name="Rot",    col=Color3.fromRGB(255,60,60)   },
    { name="Gelb",   col=Color3.fromRGB(255,220,0)   },
    { name="Lila",   col=Color3.fromRGB(180,60,255)  },
}
for _, cp in ipairs(espBoxColPresets) do
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 30, 0, 16)
    sw.BackgroundColor3 = cp.col
    sw.BackgroundTransparency = 0.15
    sw.BorderSizePixel = 0
    sw.Text = cp.name
    sw.Font = Enum.Font.Gotham
    sw.TextSize = 7
    sw.TextColor3 = Color3.fromRGB(0,0,0)
    sw.AutoButtonColor = false
    sw.ZIndex = 6
    sw.Parent = espBoxColorRow
    addCorner(sw, 4)
    sw.MouseButton1Click:Connect(function()
        espBoxColor = cp.col
        rebuildPreview()
    end)
end

-- Name Farben
local espTxtColorCard = Instance.new("Frame")
espTxtColorCard.Name = "ESPTxtColorCard"
espTxtColorCard.Size = UDim2.new(1, 0, 0, 52)
espTxtColorCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
espTxtColorCard.BackgroundTransparency = 0.97
espTxtColorCard.BorderSizePixel = 0
espTxtColorCard.ZIndex = 4
espTxtColorCard.Parent = VisualPage
addCorner(espTxtColorCard, 8)
addStroke(espTxtColorCard, Color3.fromRGB(255, 255, 255), 1, 0.94)

local espTxtColorTitle = Instance.new("TextLabel")
espTxtColorTitle.BackgroundTransparency = 1
espTxtColorTitle.Position = UDim2.new(0, 12, 0, 7)
espTxtColorTitle.Size = UDim2.new(1, -24, 0, 14)
espTxtColorTitle.Font = Enum.Font.GothamMedium
espTxtColorTitle.Text = "Text / Name Farbe"
espTxtColorTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
espTxtColorTitle.TextSize = 11
espTxtColorTitle.TextXAlignment = Enum.TextXAlignment.Left
espTxtColorTitle.ZIndex = 5
espTxtColorTitle.Parent = espTxtColorCard

local espTxtColorRow = Instance.new("Frame")
espTxtColorRow.BackgroundTransparency = 1
espTxtColorRow.Position = UDim2.new(0, 10, 0, 26)
espTxtColorRow.Size = UDim2.new(1, -20, 0, 20)
espTxtColorRow.ZIndex = 5
espTxtColorRow.Parent = espTxtColorCard

local espTcLayout = Instance.new("UIListLayout")
espTcLayout.FillDirection = Enum.FillDirection.Horizontal
espTcLayout.Padding = UDim.new(0, 5)
espTcLayout.Parent = espTxtColorRow

for _, cp in ipairs(espBoxColPresets) do
    local sw = Instance.new("TextButton")
    sw.Size = UDim2.new(0, 30, 0, 16)
    sw.BackgroundColor3 = cp.col
    sw.BackgroundTransparency = 0.15
    sw.BorderSizePixel = 0
    sw.Text = cp.name
    sw.Font = Enum.Font.Gotham
    sw.TextSize = 7
    sw.TextColor3 = Color3.fromRGB(0,0,0)
    sw.AutoButtonColor = false
    sw.ZIndex = 6
    sw.Parent = espTxtColorRow
    addCorner(sw, 4)
    sw.MouseButton1Click:Connect(function()
        espTextColor = cp.col
        rebuildPreview()
    end)
end

addSection(VisualPage, "Kamera- & Spiel-Effekte")

local noCamShake = false
local camShakeConn = nil
addToggle(VisualPage, "Disable Camera Shake", "Verhindert das Verwackeln der Kamera bei Schaden (camShakes)", false, function(enabled)
    noCamShake = enabled
    if noCamShake then
        local function cleanShaker(char)
            if not char then return end
            local cs = char:FindFirstChild("camShakes")
            if cs then cs:Destroy() end
        end
        cleanShaker(LocalPlayer.Character)
        camShakeConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            cleanShaker(char)
        end)
    else
        if camShakeConn then camShakeConn:Disconnect(); camShakeConn = nil end
    end
end)

local noBobbing = false
local bobbingConn = nil
addToggle(VisualPage, "Disable Camera Bobbing", "Entfernt das Wackeln der Kamera beim Gehen (CameraBobbing)", false, function(enabled)
    noBobbing = enabled
    if noBobbing then
        local function cleanBobbing(char)
            if not char then return end
            local cb = char:FindFirstChild("CameraBobbing")
            if cb then cb:Destroy() end
        end
        cleanBobbing(LocalPlayer.Character)
        bobbingConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            cleanBobbing(char)
        end)
    else
        if bobbingConn then bobbingConn:Disconnect(); bobbingConn = nil end
    end
end)

local noHeadshotEffect = false
local headshotConn = nil
addToggle(VisualPage, "No Headshot / Low HP Blinding", "Entfernt Blurring, Color-Tints und HushSound bei Treffern", false, function(enabled)
    noHeadshotEffect = enabled
    if noHeadshotEffect then
        local function cleanEffects(char)
            if not char then return end
            local hs = char:FindFirstChild("HEADSHOT EFFECT")
            if hs then hs:Destroy() end
            local lh = char:FindFirstChild("LowHealthEffect")
            if lh then lh:Destroy() end
        end
        cleanEffects(LocalPlayer.Character)
        pcall(function()
            local hush = game.SoundService:FindFirstChild("HushSound")
            if hush then hush:Stop() end
            local cc = game.Lighting:FindFirstChild("ColorCorrection")
            if cc then cc.TintColor = Color3.fromRGB(255, 255, 255) end
        end)
        headshotConn = LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            cleanEffects(char)
        end)
    else
        if headshotConn then headshotConn:Disconnect(); headshotConn = nil end
    end
end)

local disableWeather = false
addToggle(VisualPage, "Disable Rain & Thunder Weather", "Entfernt Regenpartikel & Gewittersounds (FPS Boost)", false, function(enabled)
    disableWeather = enabled
    while disableWeather do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local rp = char:FindFirstChild("RAIN PARTS")
                if rp then rp:Destroy() end
            end
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rs = hrp:FindFirstChild("RainSound")
                if rs then rs:Stop() end
                local ts = hrp:FindFirstChild("ThunderSounds")
                if ts then ts:Destroy() end
            end
            for _, v in ipairs(workspace.CurrentCamera:GetChildren()) do
                if v:IsA("BasePart") and (v.Name:find("Rain") or v.Name:find("RAIN")) then
                    v:Destroy()
                end
            end
        end)
        task.wait(1)
    end
end)

local staticCarFov = false
addToggle(VisualPage, "Static Car FOV (No FOV Zoom)", "Verhindert, dass Autos das Kamera-FOV auf 90 ziehen", false, function(enabled)
    staticCarFov = enabled
    if staticCarFov then
        local function cleanCarFov(char)
            if not char then return end
            local cf = char:FindFirstChild("Car FOV")
            if cf then cf:Destroy() end
        end
        cleanCarFov(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            cleanCarFov(char)
        end)
    end
end)

addSection(VisualPage, "Bullet & Effect Farben")

-- Bullet Color Presets (ändern Setting.BulletColor in der aktiven Waffe)
local function applyBulletColor(color)
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local gunLocal = tool:FindFirstChild("GunScript_Local")
            local setting = tool:FindFirstChild("Setting")
            if setting and gunLocal then
                pcall(function()
                    local mod = require(setting)
                    mod.BulletColor = color
                    mod.BulletLightColor = color
                end)
            end
        end
    end
    -- Auch im Backpack versuchen
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local setting = tool:FindFirstChild("Setting")
            if setting then
                pcall(function()
                    local mod = require(setting)
                    mod.BulletColor = color
                    mod.BulletLightColor = color
                end)
            end
        end
    end
end

local bulletColorPresets = {
    { name = "🔴 Rot",         color = Color3.fromRGB(255, 50,  50)  },
    { name = "🟢 Grün",        color = Color3.fromRGB(50,  255, 80)  },
    { name = "🔵 Blau",        color = Color3.fromRGB(50,  120, 255) },
    { name = "🟡 Gelb",        color = Color3.fromRGB(255, 220, 0)   },
    { name = "🟣 Lila",        color = Color3.fromRGB(180, 0,   255) },
    { name = "🩷 Pink",        color = Color3.fromRGB(255, 80,  200) },
    { name = "🩵 Cyan",        color = Color3.fromRGB(0,   220, 255) },
    { name = "🟠 Orange",      color = Color3.fromRGB(255, 130, 0)   },
    { name = "⬜ Weiß",        color = Color3.fromRGB(255, 255, 255) },
}

for _, preset in ipairs(bulletColorPresets) do
    addButton(VisualPage, preset.name .. " Bullet", "Stellt Bullet-Farbe auf " .. preset.name .. " um", "Anwenden", function()
        applyBulletColor(preset.color)
    end)
end

-- Hand Trail Color (Faust-Trail beim Schlagen)
addSection(VisualPage, "Hand-Trail Farbe (Faust / Schlag)")

local function applyHandTrailColor(color)
    local char = LocalPlayer.Character
    if not char then return end
    local trail = char:FindFirstChild("HandTrail")
    if trail then
        trail.Color = ColorSequence.new(color)
    end
    -- Auch auf neue Trails vorbereiten
    char.ChildAdded:Connect(function(child)
        if child.Name == "HandTrail" then
            child.Color = ColorSequence.new(color)
        end
    end)
end

local trailColorPresets = {
    { name = "🔴 Rot",     color = Color3.fromRGB(255, 50,  50)  },
    { name = "🔵 Blau",    color = Color3.fromRGB(50,  120, 255) },
    { name = "🟢 Grün",    color = Color3.fromRGB(50,  255, 80)  },
    { name = "🟡 Gelb",    color = Color3.fromRGB(255, 220, 0)   },
    { name = "🟣 Lila",    color = Color3.fromRGB(180, 0,   255) },
    { name = "⬜ Weiß",    color = Color3.fromRGB(255, 255, 255) },
    { name = "🩵 Cyan",    color = Color3.fromRGB(0,   220, 255) },
    { name = "🩷 Pink",    color = Color3.fromRGB(255, 80,  200) },
}

for _, preset in ipairs(trailColorPresets) do
    addButton(VisualPage, preset.name .. " Trail", "Setzt Hand-Trail auf " .. preset.name, "Anwenden", function()
        applyHandTrailColor(preset.color)
    end)
end

-- Smoke / ParticleEmitter auf dem Charakter einfärben
addSection(VisualPage, "Charakter Rauch & Partikel Farbe")

local function applyCharParticleColor(color)
    local char = LocalPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Smoke") or desc:IsA("Fire") then
            pcall(function()
                if desc:IsA("ParticleEmitter") then
                    desc.Color = ColorSequence.new(color)
                elseif desc:IsA("Smoke") then
                    desc.Color = color
                elseif desc:IsA("Fire") then
                    desc.Color = color
                    desc.SecondaryColor = color
                end
            end)
        end
    end
end

local particleColorPresets = {
    { name = "🔴 Rot",   color = Color3.fromRGB(255, 50,  50)  },
    { name = "🔵 Blau",  color = Color3.fromRGB(50,  120, 255) },
    { name = "🟢 Grün",  color = Color3.fromRGB(50,  255, 80)  },
    { name = "🟣 Lila",  color = Color3.fromRGB(180, 0,   255) },
    { name = "⬜ Weiß",  color = Color3.fromRGB(255, 255, 255) },
    { name = "🩵 Cyan",  color = Color3.fromRGB(0,   220, 255) },
}

for _, preset in ipairs(particleColorPresets) do
    addButton(VisualPage, preset.name .. " Smoke/Partikel", "Färbt alle Partikel/Rauch am Char auf " .. preset.name, "Anwenden", function()
        applyCharParticleColor(preset.color)
    end)
end

----------------------------------------------------------------------
-- TAB 4: SHOP (Vollständig mit 21 Items & Filtern)
