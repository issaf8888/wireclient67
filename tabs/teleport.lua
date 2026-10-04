-- ====================================================================
-- TAB: TELEPORT
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

local TeleportPage = tabPages["Teleport"]
addSection(TeleportPage, "Wichtige Orte (Map Teleports)")

-- Teleport mit Anti-Rubber-Band Fix (Heartbeat-Spam überrumpelt Server-Korrekturen)
local function safeTeleport(cframeOrPos)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local targetCF
    if typeof(cframeOrPos) == "Vector3" then
        targetCF = CFrame.new(cframeOrPos + Vector3.new(0, 3, 0))
    elseif typeof(cframeOrPos) == "CFrame" then
        targetCF = cframeOrPos + Vector3.new(0, 3, 0)
    else
        return
    end

    -- Methode: 0.35 Sekunden lang jeden Frame die CFrame setzen
    -- Das überfordert die Server-Korrektur und bleibt am Zielort
    local endTime = tick() + 0.35
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() >= endTime then
            conn:Disconnect()
            return
        end
        local c2 = LocalPlayer.Character
        local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
        if h2 then
            h2.CFrame = targetCF
        end
    end)
end

local mapLocations = {
    { name = "Big House",       pos = Vector3.new(-1487.53, 476.30, -3748.88), desc = "Luxusanwesen auf dem Hügel" },
    { name = "Bank",            pos = Vector3.new(-1200.45, 253.78, -3640.67), desc = "Hauptbank & Tresorbereich" },
    { name = "Gun Store 1",     pos = Vector3.new(-1005.05, 253.81, -814.23),  desc = "Waffengeschäft 1" },
    { name = "Gun Store 2",     pos = Vector3.new(-235.69, 283.79, -802.53),   desc = "Waffengeschäft 2" },
    { name = "Dealer Ship 1",   pos = Vector3.new(-406.81, 253.41, -1240.38),  desc = "Autohändler 1" },
    { name = "Dealer Ship 2",   pos = Vector3.new(-1558.10, 253.86, -3840.61), desc = "Autohändler 2" },
    { name = "Exotic Shop",     pos = Vector3.new(-1483.82, 253.80, -981.36),  desc = "Exotic Black Market & Food" },
}

for _, loc in ipairs(mapLocations) do
    addButton(TeleportPage, loc.name, loc.desc, "Teleport", function()
        safeTeleport(loc.pos)
    end)
end

addSection(TeleportPage, "Farm & Spezial Teleports")

addButton(TeleportPage, "Hospital Beds (Instant Heal)", "Teleportiert zu den Betten im Krankenhaus", "Teleport", function()
    local beds = workspace:FindFirstChild("HospitalBeds")
    if beds then
        for _, bed in ipairs(beds:GetDescendants()) do
            if bed:IsA("BasePart") and bed.Name == "Bed" then
                safeTeleport(bed.CFrame)
                break
            end
        end
    end
end)

addButton(TeleportPage, "StudioPay Cash Stacks", "Teleportiert direkt zu den StudioPay Geldsäcken", "Teleport", function()
    local studio = workspace:FindFirstChild("StudioPay")
    local moneyFolder = studio and studio:FindFirstChild("Money")
    if moneyFolder then
        local stack = moneyFolder:FindFirstChild("StudioPay1") or moneyFolder:FindFirstChildWhichIsA("BasePart", true)
        if stack then
            safeTeleport(stack:IsA("BasePart") and stack.CFrame or stack:GetPivot())
        end
    end
end)

addButton(TeleportPage, "Ice-Fruit Cook Pot", "Teleportiert zum nächsten freien Kochtopf", "Teleport", function()
    local pots = workspace:FindFirstChild("CookingPots")
    if pots then
        local pot = pots:FindFirstChildWhichIsA("Model")
        if pot then safeTeleport(pot:GetPivot()) end
    end
end)

addButton(TeleportPage, "Ice-Fruit Sell Stand", "Teleportiert zum Ice-Fruit Verkaufsstand", "Teleport", function()
    local sell = workspace:FindFirstChild("IceFruit Sell")
    if sell then safeTeleport(sell:IsA("BasePart") and sell.CFrame or sell:GetPivot()) end
end)

addSection(TeleportPage, "Spieler Teleportation")

addButton(TeleportPage, "Teleport to Nearest Player", "Teleportiert dich direkt hinter den nächsten Spieler", "TP Nearest", function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local nearest = nil
    local nearestDist = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myHrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = p
            end
        end
    end

    if nearest and nearest.Character and nearest.Character:FindFirstChild("HumanoidRootPart") then
        safeTeleport(nearest.Character.HumanoidRootPart.CFrame - nearest.Character.HumanoidRootPart.CFrame.LookVector * 3)
    end
end)

addInputCard(TeleportPage, "Teleport to Player", "Gib den Namen oder Teilnamen eines Spielers ein", "Username...", "Teleport", function(text)
    if not text or text == "" then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (p.Name:lower():sub(1, #text) == text:lower() or p.DisplayName:lower():sub(1, #text) == text:lower()) then
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                safeTeleport(p.Character.HumanoidRootPart.CFrame - p.Character.HumanoidRootPart.CFrame.LookVector * 3)
                break
            end
        end
    end
end)

addSection(TeleportPage, "Fliegen & Bewegungs-Hacks")

-- Anti-Teleport-Back: hält CFrame jede Frame fest bis deaktiviert
local antiTPBack = false
local antiTPBackConn = nil
local antiTPBackCF = nil
addToggle(TeleportPage, "Anti-Teleport-Back (Position Lock)", "Sperrt deine aktuelle Position – der Server kann dich nicht zurückschicken", false, function(enabled)
    antiTPBack = enabled
    if enabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            antiTPBackCF = hrp.CFrame
        end
        antiTPBackConn = RunService.Heartbeat:Connect(function()
            if not antiTPBack then
                antiTPBackConn:Disconnect()
                antiTPBackConn = nil
                return
            end
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h and antiTPBackCF then
                -- Nur Y-Richtung erlauben (normal fallen), X/Z sperren
                local cur = h.CFrame
                h.CFrame = CFrame.new(antiTPBackCF.X, cur.Y, antiTPBackCF.Z) * (cur - cur.p)
            end
        end)
    else
        if antiTPBackConn then
            antiTPBackConn:Disconnect()
            antiTPBackConn = nil
        end
        antiTPBackCF = nil
    end
end)

-- Fly System (BodyVelocity + BodyGyro – Namen mit "gun" um abcde-Filter zu umgehen)
local flyActive = false
local flySpeed = 60
local flyConn = nil
local flyVel = nil
local flyGyro = nil

local function flyCleanup()
    if flyVel and flyVel.Parent then pcall(function() flyVel:Destroy() end) end
    if flyGyro and flyGyro.Parent then pcall(function() flyGyro:Destroy() end) end
    flyVel = nil
    flyGyro = nil
    if flyConn then flyConn:Disconnect(); flyConn = nil end
end

local function flySetup()
    flyCleanup()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    hum.PlatformStand = true

    -- Namen enthalten "gun" → abcde ChildAdded-Filter überspringt sie
    flyVel = Instance.new("BodyVelocity")
    flyVel.Name = "gunFlyVelocity"
    flyVel.Velocity = Vector3.zero
    flyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyVel.Parent = hrp

    flyGyro = Instance.new("BodyGyro")
    flyGyro.Name = "gunFlyGyro"
    flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyGyro.D = 100
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp

    local UIS = game:GetService("UserInputService")
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyActive then
            flyCleanup()
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("Humanoid")
            if h then h.PlatformStand = false end
            return
        end
        local c = LocalPlayer.Character
        local h = c and c:FindFirstChild("HumanoidRootPart")
        if not h then return end

        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        if flyVel and flyVel.Parent then
            flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        end
        if flyGyro and flyGyro.Parent then
            flyGyro.CFrame = cam.CFrame
        end
    end)
end

addToggle(TeleportPage, "Fliegen (Fly Mode)", "WASD/Space/LShift zum Fliegen. Nutzt gunFlyVelocity um abcde zu umgehen.", false, function(enabled)
    flyActive = enabled
    if enabled then
        flySetup()
    else
        flyActive = false
        -- flyCleanup wird im RenderStepped ausgelöst
    end
end)

addSlider(TeleportPage, "Fluggeschwindigkeit (Fly Speed)", 10, 300, 60, function(val)
    flySpeed = val
end)

-- Charakter-Respawn → Fly neu aufsetzen
LocalPlayer.CharacterAdded:Connect(function()
    flyVel = nil
    flyGyro = nil
    flyConn = nil
    if flyActive then
        task.wait(1)
        flySetup()
    end
end)

----------------------------------------------------------------------
-- TAB 3: VISUELL (AMBIENT LIGHTING & COLOR CHANGER!)
