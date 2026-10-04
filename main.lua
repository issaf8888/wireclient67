--[[
    ═══════════════════════════════════════════════════════════════
    ★ wire.win - Premium Clean Lua GUI (V7 Ultimate+) ★
    - Full Black Aesthetic & abgerundete Ecken (UICorner)
    - Keine vierkantigen Boxen im Loading Screen (100% Vektor)
    - 7-Sekunden Loading Screen ("wire.win", hohler Outline-Ladering, "pls wait rq")
    - Exakt gleiche Fenstergröße (580 x 380) für Loading & Main GUI
    - Feine, dünne Linien (1px Strokes) & schlanke Typografie
    - Interaktiver Partikel-Hintergrund (Maus-Abstoßungs-Physik)
    
    ★ ALLE 8 TABS VOLLSTÄNDIG IMPLEMENTIERT (INKL. ALLE NEUEN EXPLOITS & REMOTES):
      1. Money    -> Bank Deposit ($10k), CashApp Wire Transfer, Drop Cash Spammer, ATM Loop, Ice-Fruit Dupe, StudioPay
      2. Aim      -> Infinite Ammo, Rapid Fire / Full Auto, No Jamming, Anti-Knife Auto-Remove, Anti-Fist Stun, Keep Tools on Ragdoll, Aimbot
      3. Teleport -> 7 Map Locations, Hospital Beds, Player Teleport, FLIEGEN (Fly Mode, Anti-Rubber-Band, Position Lock)
      4. Visuell  -> Ambient Lighting, No Camera Shake, No Headshot Blinding, Disable Rain, Static Car FOV, ESP,
                     BULLET FARBEN (9 Presets), HAND-TRAIL FARBEN (8 Presets), SMOKE/PARTIKEL FARBEN (6 Presets)
      5. Shop     -> 39 Items! (21 Standard + 18 Exotic Black Market: Sledge Hammer, FakeCard, Bandage, Mags & Ammo)
      6. Farm     -> Hospital Bed Regen, Auto-Heal on Low HP, Instant Proximity Prompts, StudioPay Cash Farm
      7. Misc     -> Anti-Cheat Safe Mode, Instant Respawn, Free NYPD Police, Car Horn, FCarry, BeamToggle, WalkSpeed, Jump, Noclip,
                     FAHRZEUG SPEED (MaxSpeed + Torque Slider), GOD MODE, INFINITE STAMINA, AUTO-BLOCK, SHOW ARMS/LEGS, AUTO-CARRY
      8. Options  -> Keybind (RightControl), Particle Toggle, Unload GUI
    ═══════════════════════════════════════════════════════════════
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- Sichere Erkennung des Parent-Objekts (CoreGui für Executer, sonst PlayerGui)
local function getSafeGuiParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        return coreGui
    end
    return PlayerGui
end

-- Altes GUI löschen
local parentGui = getSafeGuiParent()
local existing = parentGui:FindFirstChild("WireWinGui")
if existing then
    existing:Destroy()
end

-- ScreenGui anlegen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WireWinGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = parentGui

local WINDOW_SIZE = UDim2.new(0, 580, 0, 380)

----------------------------------------------------------------------
-- DESIGN-HILFSFUNKTIONEN
----------------------------------------------------------------------

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 16)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.88
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

-- Interaktives Partikelsystem
local particlesEnabled = true
local particleContainers = {}

local function createInteractiveParticles(containerFrame, count)
    count = count or 75
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleCanvas"
    particleContainer.BackgroundTransparency = 1
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.Position = UDim2.new(0, 0, 0, 0)
    particleContainer.ClipsDescendants = true
    particleContainer.ZIndex = 1
    particleContainer.Parent = containerFrame

    table.insert(particleContainers, particleContainer)

    local particles = {}
    math.randomseed(tick())

    for i = 1, count do
        local dot = Instance.new("Frame")
        dot.Name = "Dot_" .. i
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.BackgroundTransparency = math.random(30, 80) / 100
        dot.BorderSizePixel = 0
        dot.ZIndex = 1

        local dotSize = math.random(2, 3)
        dot.Size = UDim2.new(0, dotSize, 0, dotSize)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        if dotSize >= 3 then
            local pGlow = Instance.new("UIStroke")
            pGlow.Color = Color3.fromRGB(255, 255, 255)
            pGlow.Thickness = 1
            pGlow.Transparency = 0.75
            pGlow.Parent = dot
        end

        dot.Parent = particleContainer

        local initialX = math.random(5, 95) / 100
        local initialY = math.random(5, 95) / 100

        table.insert(particles, {
            gui = dot,
            homeX = initialX,
            homeY = initialY,
            currentX = initialX,
            currentY = initialY,
            vx = 0,
            vy = 0,
            driftPhaseX = math.random() * math.pi * 2,
            driftPhaseY = math.random() * math.pi * 2,
            driftSpeedX = (math.random(3, 8) / 1000) * (math.random() > 0.5 and 1 or -1),
            driftSpeedY = (math.random(3, 8) / 1000) * (math.random() > 0.5 and 1 or -1)
        })
    end

    local heartbeatConn
    heartbeatConn = RunService.RenderStepped:Connect(function(dt)
        if not particlesEnabled or not containerFrame or not containerFrame.Parent or not containerFrame.Visible then
            return
        end

        local mousePos = UserInputService:GetMouseLocation()
        local framePos = containerFrame.AbsolutePosition
        local frameSize = containerFrame.AbsoluteSize

        if frameSize.X <= 0 or frameSize.Y <= 0 then return end

        local relMouseX = (mousePos.X - framePos.X) / frameSize.X
        local relMouseY = (mousePos.Y - framePos.Y) / frameSize.Y

        local isMouseNear = relMouseX >= -0.1 and relMouseX <= 1.1 and relMouseY >= -0.1 and relMouseY <= 1.1
        local repelRadius = 0.20

        for _, p in ipairs(particles) do
            p.driftPhaseX = p.driftPhaseX + p.driftSpeedX
            p.driftPhaseY = p.driftPhaseY + p.driftSpeedY
            local targetHomeX = p.homeX + math.sin(p.driftPhaseX) * 0.03
            local targetHomeY = p.homeY + math.cos(p.driftPhaseY) * 0.03

            local forceX, forceY = 0, 0
            if isMouseNear then
                local dx = p.currentX - relMouseX
                local dy = p.currentY - relMouseY
                local dist = math.sqrt(dx * dx + dy * dy)

                if dist < repelRadius and dist > 0.001 then
                    local repelPower = (1 - (dist / repelRadius)) ^ 1.8 * 1.1
                    forceX = (dx / dist) * repelPower
                    forceY = (dy / dist) * repelPower
                end
            end

            local springK = 5.5
            local damping = 0.80

            local returnForceX = (targetHomeX - p.currentX) * springK
            local returnForceY = (targetHomeY - p.currentY) * springK

            p.vx = (p.vx + (returnForceX + forceX * 16) * dt) * damping
            p.vy = (p.vy + (returnForceY + forceY * 16) * dt) * damping

            p.currentX = math.clamp(p.currentX + p.vx * dt, 0.02, 0.98)
            p.currentY = math.clamp(p.currentY + p.vy * dt, 0.02, 0.98)

            p.gui.Position = UDim2.new(p.currentX, 0, p.currentY, 0)
        end
    end)

    return heartbeatConn
end

-- Draggable Window System
local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            TweenService:Create(frame, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Position = newPos
            }):Play()
        end
    end)
end

----------------------------------------------------------------------
-- 1. LOADING SCREEN (100% Clean)
----------------------------------------------------------------------

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = WINDOW_SIZE
LoadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
LoadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
LoadingFrame.BorderSizePixel = 0
LoadingFrame.ClipsDescendants = true
LoadingFrame.Parent = ScreenGui

addCorner(LoadingFrame, 16)
addStroke(LoadingFrame, Color3.fromRGB(255, 255, 255), 1, 0.88)

local loadingParticleConn = createInteractiveParticles(LoadingFrame, 75)

local LoadingContent = Instance.new("Frame")
LoadingContent.Name = "LoadingContent"
LoadingContent.BackgroundTransparency = 1
LoadingContent.Size = UDim2.new(1, 0, 1, 0)
LoadingContent.ZIndex = 2
LoadingContent.Parent = LoadingFrame

-- TITEL: "wire.win" mit Glow
local TitleContainer = Instance.new("Frame")
TitleContainer.Name = "TitleContainer"
TitleContainer.BackgroundTransparency = 1
TitleContainer.BorderSizePixel = 0
TitleContainer.Size = UDim2.new(1, 0, 0, 40)
TitleContainer.Position = UDim2.new(0, 0, 0, 78)
TitleContainer.ZIndex = 3
TitleContainer.Parent = LoadingContent

local TitleGlowOuter = Instance.new("TextLabel")
TitleGlowOuter.Name = "TitleGlowOuter"
TitleGlowOuter.BackgroundTransparency = 1
TitleGlowOuter.BorderSizePixel = 0
TitleGlowOuter.Size = UDim2.new(1, 0, 1, 0)
TitleGlowOuter.Font = Enum.Font.GothamMedium
TitleGlowOuter.Text = "wire.win"
TitleGlowOuter.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleGlowOuter.TextSize = 25
TitleGlowOuter.TextTransparency = 0.5
TitleGlowOuter.ZIndex = 3
TitleGlowOuter.Parent = TitleContainer

local titleStrokeOuter = Instance.new("UIStroke")
titleStrokeOuter.Color = Color3.fromRGB(255, 255, 255)
titleStrokeOuter.Thickness = 3
titleStrokeOuter.Transparency = 0.65
titleStrokeOuter.Parent = TitleGlowOuter

local TitleGlowInner = Instance.new("TextLabel")
TitleGlowInner.Name = "TitleGlowInner"
TitleGlowInner.BackgroundTransparency = 1
TitleGlowInner.BorderSizePixel = 0
TitleGlowInner.Size = UDim2.new(1, 0, 1, 0)
TitleGlowInner.Font = Enum.Font.GothamMedium
TitleGlowInner.Text = "wire.win"
TitleGlowInner.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleGlowInner.TextSize = 25
TitleGlowInner.TextTransparency = 0.2
TitleGlowInner.ZIndex = 4
TitleGlowInner.Parent = TitleContainer

local titleStrokeInner = Instance.new("UIStroke")
titleStrokeInner.Color = Color3.fromRGB(255, 255, 255)
titleStrokeInner.Thickness = 1.2
titleStrokeInner.Transparency = 0.35
titleStrokeInner.Parent = TitleGlowInner

local TitleMain = Instance.new("TextLabel")
TitleMain.Name = "TitleMain"
TitleMain.BackgroundTransparency = 1
TitleMain.BorderSizePixel = 0
TitleMain.Size = UDim2.new(1, 0, 1, 0)
TitleMain.Font = Enum.Font.GothamMedium
TitleMain.Text = "wire.win"
TitleMain.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleMain.TextSize = 25
TitleMain.ZIndex = 5
TitleMain.Parent = TitleContainer

task.spawn(function()
    while LoadingFrame.Parent and LoadingFrame.Visible do
        local t1 = TweenService:Create(titleStrokeOuter, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.35,
            Thickness = 4
        })
        local t2 = TweenService:Create(titleStrokeInner, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.15
        })
        t1:Play()
        t2:Play()
        t1.Completed:Wait()

        local t3 = TweenService:Create(titleStrokeOuter, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.8,
            Thickness = 2.2
        })
        local t4 = TweenService:Create(titleStrokeInner, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Transparency = 0.5
        })
        t3:Play()
        t4:Play()
        t3.Completed:Wait()
    end
end)

-- HOHLER LADEKREIS
local SpinnerWrapper = Instance.new("Frame")
SpinnerWrapper.Name = "SpinnerWrapper"
SpinnerWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
SpinnerWrapper.Position = UDim2.new(0.5, 0, 0.53, 0)
SpinnerWrapper.Size = UDim2.new(0, 56, 0, 56)
SpinnerWrapper.BackgroundTransparency = 1
SpinnerWrapper.BorderSizePixel = 0
SpinnerWrapper.ZIndex = 3
SpinnerWrapper.Parent = LoadingContent

local HollowTrackCircle = Instance.new("Frame")
HollowTrackCircle.AnchorPoint = Vector2.new(0.5, 0.5)
HollowTrackCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
HollowTrackCircle.Size = UDim2.new(1, 0, 1, 0)
HollowTrackCircle.BackgroundTransparency = 1
HollowTrackCircle.BorderSizePixel = 0
HollowTrackCircle.ZIndex = 3
HollowTrackCircle.Parent = SpinnerWrapper

addCorner(HollowTrackCircle, 28)
local trackStroke = addStroke(HollowTrackCircle, Color3.fromRGB(255, 255, 255), 1.4, 0.90)

local HollowSpinnerCircle = Instance.new("Frame")
HollowSpinnerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
HollowSpinnerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
HollowSpinnerCircle.Size = UDim2.new(1, 0, 1, 0)
HollowSpinnerCircle.BackgroundTransparency = 1
HollowSpinnerCircle.BorderSizePixel = 0
HollowSpinnerCircle.ZIndex = 4
HollowSpinnerCircle.Parent = SpinnerWrapper

addCorner(HollowSpinnerCircle, 28)
local spinnerStroke = addStroke(HollowSpinnerCircle, Color3.fromRGB(255, 255, 255), 1.5, 0)

local spinnerGradient = Instance.new("UIGradient")
spinnerGradient.Name = "ArcGradient"
spinnerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
spinnerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.35, 0.05),
    NumberSequenceKeypoint.new(0.65, 0.9),
    NumberSequenceKeypoint.new(1, 1)
})
spinnerGradient.Parent = spinnerStroke

local spinnerConn
spinnerConn = RunService.RenderStepped:Connect(function(dt)
    if not SpinnerWrapper or not SpinnerWrapper.Parent then return end
    spinnerGradient.Rotation = (spinnerGradient.Rotation + 240 * dt) % 360
end)

-- TEXT: "pls wait rq"
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.BackgroundTransparency = 1
StatusLabel.BorderSizePixel = 0
StatusLabel.Size = UDim2.new(1, 0, 0, 24)
StatusLabel.Position = UDim2.new(0, 0, 0.68, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "pls wait rq"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 13
StatusLabel.TextTransparency = 0.35
StatusLabel.ZIndex = 3
StatusLabel.Parent = LoadingContent

addStroke(StatusLabel, Color3.fromRGB(255, 255, 255), 1, 0.8)

task.spawn(function()
    while LoadingFrame.Parent and LoadingFrame.Visible do
        local t1 = TweenService:Create(StatusLabel, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.7
        })
        t1:Play()
        t1.Completed:Wait()

        local t2 = TweenService:Create(StatusLabel, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            TextTransparency = 0.2
        })
        t2:Play()
        t2.Completed:Wait()
    end
end)

----------------------------------------------------------------------
-- 2. MAIN GUI WINDOW & SIDEBAR
----------------------------------------------------------------------

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = WINDOW_SIZE
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

addCorner(MainFrame, 16)
addStroke(MainFrame, Color3.fromRGB(255, 255, 255), 1, 0.88)

local mainParticleConn = createInteractiveParticles(MainFrame, 80)

-- Header Bar
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.BackgroundTransparency = 1
HeaderBar.BorderSizePixel = 0
HeaderBar.Size = UDim2.new(1, 0, 0, 48)
HeaderBar.Position = UDim2.new(0, 0, 0, 0)
HeaderBar.ZIndex = 3
HeaderBar.Parent = MainFrame

local HeaderDivider = Instance.new("Frame")
HeaderDivider.Name = "Divider"
HeaderDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderDivider.BackgroundTransparency = 0.94
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Size = UDim2.new(1, -32, 0, 1)
HeaderDivider.Position = UDim2.new(0, 16, 1, -1)
HeaderDivider.ZIndex = 3
HeaderDivider.Parent = HeaderBar

-- Header Titel
local MainTitleGlow = Instance.new("TextLabel")
MainTitleGlow.Name = "TitleGlow"
MainTitleGlow.BackgroundTransparency = 1
MainTitleGlow.BorderSizePixel = 0
MainTitleGlow.Size = UDim2.new(0, 120, 1, 0)
MainTitleGlow.Position = UDim2.new(0, 20, 0, 0)
MainTitleGlow.Font = Enum.Font.GothamMedium
MainTitleGlow.Text = "wire.win"
MainTitleGlow.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTitleGlow.TextSize = 17
MainTitleGlow.TextXAlignment = Enum.TextXAlignment.Left
MainTitleGlow.TextTransparency = 0.4
MainTitleGlow.ZIndex = 3
MainTitleGlow.Parent = HeaderBar

local mainTitleStroke = Instance.new("UIStroke")
mainTitleStroke.Color = Color3.fromRGB(255, 255, 255)
mainTitleStroke.Thickness = 2
mainTitleStroke.Transparency = 0.55
mainTitleStroke.Parent = MainTitleGlow

local MainTitle = Instance.new("TextLabel")
MainTitle.Name = "Title"
MainTitle.BackgroundTransparency = 1
MainTitle.BorderSizePixel = 0
MainTitle.Size = UDim2.new(0, 120, 1, 0)
MainTitle.Position = UDim2.new(0, 20, 0, 0)
MainTitle.Font = Enum.Font.GothamMedium
MainTitle.Text = "wire.win"
MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTitle.TextSize = 17
MainTitle.TextXAlignment = Enum.TextXAlignment.Left
MainTitle.ZIndex = 4
MainTitle.Parent = HeaderBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -16, 0.5, 0)
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.96
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.Gotham
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.TextSize = 12
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 4
CloseBtn.Parent = HeaderBar
addCorner(CloseBtn, 7)
addStroke(CloseBtn, Color3.fromRGB(255, 255, 255), 1, 0.92)

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.85,
        TextColor3 = Color3.fromRGB(255, 95, 95)
    }):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.96,
        TextColor3 = Color3.fromRGB(180, 180, 180)
    }):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    closeTween:Play()
    closeTween.Completed:Wait()
    ScreenGui:Destroy()
end)

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.AnchorPoint = Vector2.new(1, 0.5)
MinBtn.Position = UDim2.new(1, -50, 0.5, 0)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 0.96
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.Gotham
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MinBtn.TextSize = 11
MinBtn.AutoButtonColor = false
MinBtn.ZIndex = 4
MinBtn.Parent = HeaderBar
addCorner(MinBtn, 7)
addStroke(MinBtn, Color3.fromRGB(255, 255, 255), 1, 0.92)

makeDraggable(MainFrame, HeaderBar)

-- Body Container
local BodyContainer = Instance.new("Frame")
BodyContainer.Name = "BodyContainer"
BodyContainer.BackgroundTransparency = 1
BodyContainer.BorderSizePixel = 0
BodyContainer.Position = UDim2.new(0, 0, 0, 48)
BodyContainer.Size = UDim2.new(1, 0, 1, -48)
BodyContainer.ZIndex = 3
BodyContainer.Parent = MainFrame

-- Sidebar
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Name = "Sidebar"
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.Position = UDim2.new(0, 14, 0, 12)
Sidebar.Size = UDim2.new(0, 126, 1, -24)
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageTransparency = 0.85
Sidebar.ClipsDescendants = true
Sidebar.ZIndex = 3
Sidebar.Parent = BodyContainer

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = Sidebar

local SideDivider = Instance.new("Frame")
SideDivider.Name = "SideDivider"
SideDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SideDivider.BackgroundTransparency = 0.94
SideDivider.BorderSizePixel = 0
SideDivider.Position = UDim2.new(0, 150, 0, 12)
SideDivider.Size = UDim2.new(0, 1, 1, -24)
SideDivider.ZIndex = 3
SideDivider.Parent = BodyContainer

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.Position = UDim2.new(0, 162, 0, 12)
ContentArea.Size = UDim2.new(1, -176, 1, -24)
ContentArea.ClipsDescendants = true
ContentArea.ZIndex = 3
ContentArea.Parent = BodyContainer

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        BodyContainer.Visible = false
        TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(WINDOW_SIZE.X.Scale, WINDOW_SIZE.X.Offset, 0, 48)
        }):Play()
    else
        local expandTween = TweenService:Create(MainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = WINDOW_SIZE
        })
        expandTween:Play()
        expandTween.Completed:Wait()
        BodyContainer.Visible = true
    end
end)

----------------------------------------------------------------------
-- UI-ELEMENT GENERATOREN (Für alle Tabs)
----------------------------------------------------------------------

local function createScrollPage(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Page_" .. name
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    scroll.ScrollBarImageTransparency = 0.8
    scroll.ClipsDescendants = true
    scroll.Visible = false
    scroll.ZIndex = 3
    scroll.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = scroll

    return scroll
end

local function addSection(parent, title)
    local header = Instance.new("Frame")
    header.Name = "Header_" .. title
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 22)
    header.ZIndex = 4
    header.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Font = Enum.Font.GothamBold
    label.Text = title:upper()
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = header

    local line = Instance.new("Frame")
    line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    line.BackgroundTransparency = 0.92
    line.BorderSizePixel = 0
    line.Position = UDim2.new(0, 0, 1, -1)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.ZIndex = 4
    line.Parent = header

    return header
end

local function addToggle(parent, title, desc, defaultVal, callback)
    local card = Instance.new("Frame")
    card.Name = "Toggle_" .. title
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.97
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = parent
    addCorner(card, 8)
    addStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.94)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, desc and 6 or 12)
    titleLabel.Size = UDim2.new(1, -70, 0, 16)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 5
    titleLabel.Parent = card

    if desc then
        local descLabel = Instance.new("TextLabel")
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 12, 0, 22)
        descLabel.Size = UDim2.new(1, -70, 0, 14)
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 5
        descLabel.Parent = card
    end

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
    toggleBtn.Position = UDim2.new(1, -12, 0.5, 0)
    toggleBtn.Size = UDim2.new(0, 38, 0, 20)
    toggleBtn.BackgroundColor3 = defaultVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
    toggleBtn.BackgroundTransparency = defaultVal and 0.1 or 0.5
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.ZIndex = 5
    toggleBtn.Parent = card
    addCorner(toggleBtn, 10)
    local toggleStroke = addStroke(toggleBtn, Color3.fromRGB(255, 255, 255), 1, 0.85)

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = defaultVal and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = toggleBtn
    addCorner(knob, 8)

    local state = defaultVal
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30),
            BackgroundTransparency = state and 0.1 or 0.5
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            BackgroundColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 200)
        }):Play()
        if callback then
            task.spawn(callback, state)
        end
    end)

    return card
end

local function addButton(parent, title, desc, btnText, callback)
    local card = Instance.new("Frame")
    card.Name = "ButtonCard_" .. title
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.97
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = parent
    addCorner(card, 8)
    addStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.94)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, desc and 6 or 12)
    titleLabel.Size = UDim2.new(1, -100, 0, 16)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 5
    titleLabel.Parent = card

    if desc then
        local descLabel = Instance.new("TextLabel")
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 12, 0, 22)
        descLabel.Size = UDim2.new(1, -100, 0, 14)
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 5
        descLabel.Parent = card
    end

    local actionBtn = Instance.new("TextButton")
    actionBtn.AnchorPoint = Vector2.new(1, 0.5)
    actionBtn.Position = UDim2.new(1, -10, 0.5, 0)
    actionBtn.Size = UDim2.new(0, 74, 0, 26)
    actionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.BackgroundTransparency = 0.93
    actionBtn.BorderSizePixel = 0
    actionBtn.Font = Enum.Font.GothamMedium
    actionBtn.Text = btnText or "Execute"
    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.TextSize = 11
    actionBtn.AutoButtonColor = false
    actionBtn.ZIndex = 5
    actionBtn.Parent = card
    addCorner(actionBtn, 6)
    local aStroke = addStroke(actionBtn, Color3.fromRGB(255, 255, 255), 1, 0.88)

    actionBtn.MouseEnter:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.82
        }):Play()
        TweenService:Create(aStroke, TweenInfo.new(0.2), {
            Transparency = 0.7
        }):Play()
    end)

    actionBtn.MouseLeave:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.93
        }):Play()
        TweenService:Create(aStroke, TweenInfo.new(0.2), {
            Transparency = 0.88
        }):Play()
    end)

    actionBtn.MouseButton1Click:Connect(function()
        local orig = actionBtn.Text
        actionBtn.Text = "..."
        if callback then
            task.spawn(function()
                local ok = pcall(callback)
                actionBtn.Text = ok and "✓" or "✕"
                task.wait(0.8)
                actionBtn.Text = orig
            end)
        end
    end)

    return card
end

local function addInputCard(parent, title, desc, placeholder, btnText, callback)
    local card = Instance.new("Frame")
    card.Name = "InputCard_" .. title
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.97
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = parent
    addCorner(card, 8)
    addStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.94)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, desc and 6 or 16)
    titleLabel.Size = UDim2.new(1, -210, 0, 16)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 5
    titleLabel.Parent = card

    if desc then
        local descLabel = Instance.new("TextLabel")
        descLabel.BackgroundTransparency = 1
        descLabel.Position = UDim2.new(0, 12, 0, 24)
        descLabel.Size = UDim2.new(1, -210, 0, 22)
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = desc
        descLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        descLabel.TextSize = 10
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextWrapped = true
        descLabel.ZIndex = 5
        descLabel.Parent = card
    end

    local textBox = Instance.new("TextBox")
    textBox.AnchorPoint = Vector2.new(1, 0.5)
    textBox.Position = UDim2.new(1, -82, 0.5, 0)
    textBox.Size = UDim2.new(0, 110, 0, 26)
    textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    textBox.BackgroundTransparency = 0.95
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = placeholder or "Amount..."
    textBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 110)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.TextSize = 11
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 5
    textBox.Parent = card
    addCorner(textBox, 6)
    addStroke(textBox, Color3.fromRGB(255, 255, 255), 1, 0.88)

    local actionBtn = Instance.new("TextButton")
    actionBtn.AnchorPoint = Vector2.new(1, 0.5)
    actionBtn.Position = UDim2.new(1, -10, 0.5, 0)
    actionBtn.Size = UDim2.new(0, 66, 0, 26)
    actionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.BackgroundTransparency = 0.93
    actionBtn.BorderSizePixel = 0
    actionBtn.Font = Enum.Font.GothamMedium
    actionBtn.Text = btnText or "Send"
    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.TextSize = 11
    actionBtn.AutoButtonColor = false
    actionBtn.ZIndex = 5
    actionBtn.Parent = card
    addCorner(actionBtn, 6)
    local aStroke = addStroke(actionBtn, Color3.fromRGB(255, 255, 255), 1, 0.88)

    actionBtn.MouseEnter:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.82 }):Play()
        TweenService:Create(aStroke, TweenInfo.new(0.2), { Transparency = 0.7 }):Play()
    end)
    actionBtn.MouseLeave:Connect(function()
        TweenService:Create(actionBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.93 }):Play()
        TweenService:Create(aStroke, TweenInfo.new(0.2), { Transparency = 0.88 }):Play()
    end)

    actionBtn.MouseButton1Click:Connect(function()
        local orig = actionBtn.Text
        actionBtn.Text = "..."
        if callback then
            task.spawn(function()
                local ok = pcall(function() callback(textBox.Text) end)
                actionBtn.Text = ok and "✓" or "✕"
                task.wait(0.8)
                actionBtn.Text = orig
            end)
        end
    end)

    return card
end

local function addSlider(parent, title, minVal, maxVal, defaultVal, callback)
    local card = Instance.new("Frame")
    card.Name = "Slider_" .. title
    card.Size = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.97
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = parent
    addCorner(card, 8)
    addStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.94)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, 6)
    titleLabel.Size = UDim2.new(1, -60, 0, 16)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 5
    titleLabel.Parent = card

    local valLabel = Instance.new("TextLabel")
    valLabel.AnchorPoint = Vector2.new(1, 0)
    valLabel.BackgroundTransparency = 1
    valLabel.Position = UDim2.new(1, -12, 0, 6)
    valLabel.Size = UDim2.new(0, 50, 0, 16)
    valLabel.Font = Enum.Font.Gotham
    valLabel.Text = tostring(defaultVal)
    valLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    valLabel.TextSize = 11
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.ZIndex = 5
    valLabel.Parent = card

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 12, 0, 32)
    track.Size = UDim2.new(1, -24, 0, 4)
    track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BackgroundTransparency = 0.9
    track.BorderSizePixel = 0
    track.ZIndex = 5
    track.Parent = card
    addCorner(track, 2)

    local fillRatio = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(fillRatio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BackgroundTransparency = 0.15
    fill.BorderSizePixel = 0
    fill.ZIndex = 6
    fill.Parent = track
    addCorner(fill, 2)

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Size = UDim2.new(1, 0, 0, 16)
    sliderBtn.Position = UDim2.new(0, 0, 0, -6)
    sliderBtn.Text = ""
    sliderBtn.ZIndex = 7
    sliderBtn.Parent = track

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(minVal + ((maxVal - minVal) * pos))
        valLabel.Text = tostring(val)
        if callback then
            task.spawn(callback, val)
        end
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return card
end

----------------------------------------------------------------------
-- 3. INITIALISIERUNG ALLER 7 TABS
----------------------------------------------------------------------

-- Clean minimal symbol icons (Unicode text, NOT emoji)
local tabIcons = {
    Money    = "$",
    Aim      = "+",
    Teleport = ">",
    Visuell  = "o",
    Shop     = "#",
    Farm     = "*",
    Misc     = "~",
    Options  = "=",
}

local tabNames = {
    { name = "Money"    },
    { name = "Aim"      },
    { name = "Teleport" },
    { name = "Visuell"  },
    { name = "Shop"     },
    { name = "Farm"     },
    { name = "Misc"     },
    { name = "Options"  },
}

local tabButtons = {}
local tabPages = {}
local activeTabName = "Shop"

for _, entry in ipairs(tabNames) do
    tabPages[entry.name] = createScrollPage(entry.name)
end

local function selectTab(targetName)
    activeTabName = targetName

    for name, btnData in pairs(tabButtons) do
        local isActive = (name == targetName)
        local btn = btnData.button
        local stroke = btnData.stroke
        local indicator = btnData.indicator
        local nameLabel = btnData.nameLabel
        local iconImage = btnData.iconImage

        if isActive then
            TweenService:Create(btn, TweenInfo.new(0.25), {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.92,
            }):Play()
            TweenService:Create(nameLabel, TweenInfo.new(0.25), {
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            TweenService:Create(iconImage, TweenInfo.new(0.25), {
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.25), {
                Transparency = 0.75
            }):Play()
            TweenService:Create(indicator, TweenInfo.new(0.25), {
                BackgroundTransparency = 0.1,
                Size = UDim2.new(0, 3, 0, 16)
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.25), {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.98,
            }):Play()
            TweenService:Create(nameLabel, TweenInfo.new(0.25), {
                TextColor3 = Color3.fromRGB(150, 150, 150)
            }):Play()
            TweenService:Create(iconImage, TweenInfo.new(0.25), {
                TextColor3 = Color3.fromRGB(110, 110, 110)
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.25), {
                Transparency = 0.95
            }):Play()
            TweenService:Create(indicator, TweenInfo.new(0.25), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 3, 0, 0)
            }):Play()
        end
    end

    for name, page in pairs(tabPages) do
        page.Visible = (name == targetName)
    end
end


for order, entry in ipairs(tabNames) do
    local name = entry.name

    local btn = Instance.new("TextButton")
    btn.Name = "Btn_" .. name
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, -6, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundTransparency = (name == activeTabName) and 0.92 or 0.98
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.Parent = Sidebar

    addCorner(btn, 8)
    local btnStroke = addStroke(btn, Color3.fromRGB(255, 255, 255), 1, (name == activeTabName) and 0.75 or 0.95)

    -- Active indicator bar
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.Position = UDim2.new(0, 7, 0.5, 0)
    indicator.Size = (name == activeTabName) and UDim2.new(0, 3, 0, 16) or UDim2.new(0, 3, 0, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    indicator.BackgroundTransparency = (name == activeTabName) and 0.1 or 1
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 5
    indicator.Parent = btn
    addCorner(indicator, 2)

    -- Icon (clean symbol TextLabel)
    local iconImage = Instance.new("TextLabel")
    iconImage.Name = "Icon"
    iconImage.BackgroundTransparency = 1
    iconImage.AnchorPoint = Vector2.new(0, 0.5)
    iconImage.Position = UDim2.new(0, 16, 0.5, 0)
    iconImage.Size = UDim2.new(0, 20, 0, 20)
    iconImage.Font = Enum.Font.GothamBold
    iconImage.Text = tabIcons[name] or "?"
    iconImage.TextColor3 = (name == activeTabName)
        and Color3.fromRGB(255, 255, 255)
        or  Color3.fromRGB(110, 110, 110)
    iconImage.TextSize = 13
    iconImage.TextXAlignment = Enum.TextXAlignment.Center
    iconImage.TextYAlignment = Enum.TextYAlignment.Center
    iconImage.ZIndex = 6
    iconImage.Parent = btn

    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Label"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 44, 0, 0)
    nameLabel.Size = UDim2.new(1, -48, 1, 0)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.Text = name
    nameLabel.TextColor3 = (name == activeTabName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 6
    nameLabel.Parent = btn

    tabButtons[name] = {
        button    = btn,
        stroke    = btnStroke,
        indicator = indicator,
        iconImage = iconImage,
        nameLabel = nameLabel
    }

    btn.MouseEnter:Connect(function()
        if activeTabName ~= name then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.94
            }):Play()
            TweenService:Create(nameLabel, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(220, 220, 220)
            }):Play()
            TweenService:Create(iconImage, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(200, 200, 200)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Transparency = 0.88
            }):Play()
        end
    end)

    btn.MouseLeave:Connect(function()
        if activeTabName ~= name then
            TweenService:Create(btn, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.98
            }):Play()
            TweenService:Create(nameLabel, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(150, 150, 150)
            }):Play()
            TweenService:Create(iconImage, TweenInfo.new(0.2), {
                TextColor3 = Color3.fromRGB(110, 110, 110)
            }):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.2), {
                Transparency = 0.95
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)
end



----------------------------------------------------------------------
-- MODULAR TAB LOADER SYSTEM (GitHub & Local)
----------------------------------------------------------------------

-- Hier deine GitHub-Daten eintragen, wenn du das Repo hochgeladen hast:
local GITHUB_USER   = "DEIN_GITHUB_NAME"
local GITHUB_REPO   = "DEIN_REPOSITORY"
local GITHUB_BRANCH = "main"

local BASE_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/tabs/",
    GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH
)

-- Globale Hilfsfunktionen für Tabs
local function showNotification(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title or "WireWin Hub",
            Text     = text or "",
            Duration = duration or 3
        })
    end)
end

local function getEquippedGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and (item:FindFirstChild("GunScript_Local") or item:FindFirstChild("GunScript") or item:FindFirstChild("Setting") or item:FindFirstChild("Configuration")) then
            return item
        end
    end
    return nil
end

-- Shared Environment / Context für alle Tabs
local sharedCtx = {
    tabPages           = tabPages,
    addSection         = addSection,
    addToggle          = addToggle,
    addButton          = addButton,
    addSlider          = addSlider,
    addInputCard       = addInputCard,
    addCorner          = addCorner,
    addStroke          = addStroke,
    showNotification   = showNotification,
    getSafeGuiParent   = getSafeGuiParent,
    getEquippedGun     = getEquippedGun,
    Players            = Players,
    LocalPlayer        = LocalPlayer,
    Camera             = Camera,
    workspace          = workspace,
    RunService         = RunService,
    TweenService       = TweenService,
    UserInputService   = UserInputService,
    Lighting           = Lighting,
    ReplicatedStorage  = ReplicatedStorage,
    ScreenGui          = ScreenGui,
    MainFrame          = MainFrame,
    particleContainers = particleContainers,
    particlesEnabled   = particlesEnabled,
}

local sharedEnv = setmetatable(sharedCtx, { __index = getfenv() })

-- Tabs Konfiguration
local tabsList = {
    { id = "Money",    file = "money.lua",    title = "Money" },
    { id = "Aim",      file = "aim.lua",      title = "Aim" },
    { id = "Teleport", file = "teleport.lua", title = "Teleport" },
    { id = "Visuell",  file = "visual.lua",   title = "Visuell" },
    { id = "Shop",     file = "shop.lua",     title = "Shop" },
    { id = "Farm",     file = "farm.lua",     title = "Farm" },
    { id = "Misc",     file = "misc.lua",     title = "Misc" },
    { id = "Options",  file = "options.lua",  title = "Options" },
}

local function fetchTabCode(fileName)
    -- 1. Lokale Datei (im Executor Workspace oder tabs-Ordner)
    local localPaths = {
        "tabs/" .. fileName,
        fileName
    }
    for _, path in ipairs(localPaths) do
        if isfile and isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 0 then
                return content, "lokal (" .. path .. ")"
            end
        end
    end

    -- 2. GitHub HttpGet
    if game and game.HttpGet then
        local url = BASE_URL .. fileName
        local ok, content = pcall(function()
            return game:HttpGet(url, true)
        end)
        if ok and content and #content > 0 and not content:find("404: Not Found") and not content:find("400: Invalid request") then
            return content, "github (" .. url .. ")"
        end
    end

    return nil, "Nicht gefunden"
end

local function loadTabModule(tabInfo)
    local code, source = fetchTabCode(tabInfo.file)
    if not code then
        warn(string.format("[WireWin] Tab '%s' konnte nicht geladen werden (%s)", tabInfo.title, tostring(source)))
        return false
    end

    local fn, parseErr = loadstring(code)
    if not fn then
        warn(string.format("[WireWin] Syntax-Fehler in '%s': %s", tabInfo.file, tostring(parseErr)))
        showNotification("Syntax-Fehler", tabInfo.file .. " hat einen Fehler!", 4)
        return false
    end

    if setfenv then
        pcall(setfenv, fn, sharedEnv)
    end

    local ok, runErr = pcall(fn, sharedCtx)
    if not ok then
        warn(string.format("[WireWin] Laufzeit-Fehler in '%s': %s", tabInfo.file, tostring(runErr)))
        showNotification("Laufzeit-Fehler", tabInfo.file .. ": " .. tostring(runErr), 4)
        return false
    end

    print(string.format("[WireWin] Tab '%s' erfolgreich geladen von %s", tabInfo.title, source))
    return true
end

-- Alle Tabs sicher laden (Fehler in einem Tab stoppen das GUI nicht!)
for _, tabInfo in ipairs(tabsList) do
    task.spawn(function()
        loadTabModule(tabInfo)
    end)
end


LoadingFrame.BackgroundTransparency = 1
TweenService:Create(LoadingFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0
}):Play()

task.spawn(function()
    task.wait(2.5)

    if spinnerConn then
        spinnerConn:Disconnect()
    end

    local fadeContent = TweenService:Create(LoadingContent, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    })
    
    TweenService:Create(TitleMain, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(TitleGlowInner, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(TitleGlowOuter, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(StatusLabel, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
    TweenService:Create(trackStroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
    TweenService:Create(spinnerStroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()

    fadeContent:Play()
    fadeContent.Completed:Wait()

    if loadingParticleConn then
        loadingParticleConn:Disconnect()
    end
    LoadingFrame:Destroy()

    MainFrame.BackgroundTransparency = 1
    MainFrame.Visible = true

    local fadeIn = TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    fadeIn:Play()
    selectTab("Shop")
end)
