-- ====================================================================
-- TAB: MISC
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

local MiscPage = tabPages["Misc"]
addSection(MiscPage, "Waffen & Gear Steuerung")

addButton(MiscPage, "Toggle Weapon Laser / Flashlight", "Aktiviert BeamToggle Remote im Spiel", "Toggle", function()
    local remote = ReplicatedStorage:FindFirstChild("BeamToggle")
    if remote then
        remote:InvokeServer()
    end
end)

addButton(MiscPage, "Holster Weapon to Front", "Holstert Waffe nach vorne (ToolReplicator)", "Front", function()
    local gun = getEquippedGun()
    local remote = ReplicatedStorage:FindFirstChild("ToolReplicator")
    if gun and remote then
        remote:FireServer(gun, "Front")
    end
end)

addButton(MiscPage, "Holster Weapon to Back", "Holstert Waffe auf den Rücken (ToolReplicator)", "Back", function()
    local gun = getEquippedGun()
    local remote = ReplicatedStorage:FindFirstChild("ToolReplicator")
    if gun and remote then
        remote:FireServer(gun, "Back")
    end
end)

addSection(MiscPage, "Audio & Sound Spammer (PlayAudio Remote)")

local function playAudioServer(soundId, volume)
    local remote = ReplicatedStorage:FindFirstChild("PlayAudio")
    local gun = getEquippedGun()
    local handle = gun and gun:FindFirstChild("Handle") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))

    if remote and handle then
        local args = {
            "}0, { \n\n } ",
            "}, { ",
            {
                Pitch = 1,
                EmitterSize = 25,
                Position = handle,
                SoundId = soundId,
                Replicate = false,
                Volume = volume or 6,
                Effects = true
            }
        }
        remote:FireServer(unpack(args))
    end
end

addButton(MiscPage, "Play Sound 1 (Beat)", "Spielt Audio 17858774599 über PlayAudio ab", "Play", function()
    playAudioServer("rbxassetid://17858774599", 7)
end)

addButton(MiscPage, "Play Sound 2 (Shoot)", "Spielt Audio 5570372235 über PlayAudio ab", "Play", function()
    playAudioServer("rbxassetid://5570372235", 6)
end)

addButton(MiscPage, "Play Sound 3 (Bass)", "Spielt Audio 4537247786 über PlayAudio ab", "Play", function()
    playAudioServer("rbxassetid://4537247786", 4)
end)

----------------------------------------------------------------------
-- ANTI-CHEAT BYPASS & PROTECTIONS (aus --abcde--.txt)
----------------------------------------------------------------------
addSection(MiscPage, "Anti-Cheat Bypass & Protections")

local antiCheatSafeMode = true
local function neutralizeAntiCheat(char)
    if not char then return end
    local abcde = char:FindFirstChild("abcde") or char:WaitForChild("abcde", 1)
    if abcde then
        pcall(function() abcde:Destroy() end)
    end
end

if LocalPlayer.Character then
    neutralizeAntiCheat(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.1)
    if antiCheatSafeMode then
        neutralizeAntiCheat(char)
    end
end)

addToggle(MiscPage, "Anti-Cheat Safe Mode (Bypass)", "Deaktiviert abcde Script - Verhindert Speed & Fly Kicks", true, function(enabled)
    antiCheatSafeMode = enabled
    if antiCheatSafeMode and LocalPlayer.Character then
        neutralizeAntiCheat(LocalPlayer.Character)
    end
end)

----------------------------------------------------------------------
-- RESPAWN & NYPD REMOTES (aus --death client-- & -- Decompiled...)
----------------------------------------------------------------------
addSection(MiscPage, "Respawn & NYPD Police Remotes")

addButton(MiscPage, "Instant Respawn (Skip 30s Timer)", "Umgeht den 30-Sekunden Todes-Countdown sofort", "Respawn", function()
    local loadRemote = ReplicatedStorage:FindFirstChild("LoadCharacter")
    if loadRemote then loadRemote:FireServer() end
    local ds = LocalPlayer.PlayerGui:FindFirstChild("deathScreen")
    if ds then ds:Destroy() end
end)

local autoInstantRespawn = false
addToggle(MiscPage, "Auto-Instant Respawn on Death", "Spawnt dich bei Tod automatisch nach 0.2s neu", false, function(enabled)
    autoInstantRespawn = enabled
end)

local function monitorDeath(char)
    local hum = char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3))
    if hum then
        hum.Died:Connect(function()
            if autoInstantRespawn then
                task.wait(0.2)
                local loadRemote = ReplicatedStorage:FindFirstChild("LoadCharacter")
                if loadRemote then loadRemote:FireServer() end
                local ds = LocalPlayer.PlayerGui:FindFirstChild("deathScreen")
                if ds then ds:Destroy() end
            end
        end)
    end
end

if LocalPlayer.Character then monitorDeath(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(monitorDeath)

addButton(MiscPage, "Sign In [NYPD Police Team]", "Tritt dem Police-Team bei (GamepassNYPDRemote)", "Sign In", function()
    local nypd = ReplicatedStorage:FindFirstChild("GamepassNYPDRemote")
    if nypd then nypd:InvokeServer("SignIn") end
end)

addButton(MiscPage, "Sign Out [NYPD Police Team]", "Verlässt das Police-Team wieder", "Sign Out", function()
    local nypd = ReplicatedStorage:FindFirstChild("GamepassNYPDRemote")
    if nypd then nypd:InvokeServer("SignOut") end
end)

----------------------------------------------------------------------
-- VEHICLES, CARRY & TROLL (aus --honk remote--, --other--, --dev console--)
----------------------------------------------------------------------
addSection(MiscPage, "Fahrzeuge, Interaktionen & System")

local honkSpam = false
addToggle(MiscPage, "Car Horn Spammer (HonkRemote)", "Dauerhupen wenn du im Auto sitzt", false, function(enabled)
    honkSpam = enabled
    while honkSpam do
        local honk = ReplicatedStorage:FindFirstChild("HonkRemote")
        if honk then pcall(function() honk:FireServer(true) end) end
        task.wait(0.12)
    end
end)

addButton(MiscPage, "FCarry: Pickup Nearest Downed", "Hebt am Boden liegende Spieler auf (FCarryRemote)", "Pickup", function()
    local fcarry = ReplicatedStorage:FindFirstChild("FCarryRemote")
    if not fcarry then return end
    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    local nearest = nil
    local minDist = 15
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            local phrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and hum.Health <= 26 and phrp then
                local dist = (myHrp.Position - phrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = p
                end
            end
        end
    end
    if nearest then
        fcarry:FireServer("Pickup", nearest.Name)
    end
end)

addButton(MiscPage, "FCarry: Drop Carried Player", "Lässt getragenen Spieler sofort fallen", "Drop", function()
    local fcarry = ReplicatedStorage:FindFirstChild("FCarryRemote")
    if fcarry then fcarry:FireServer("Drop") end
end)

addButton(MiscPage, "Toggle Developer Console", "Öffnet die Roblox Entwicklerkonsole (/console)", "Console", function()
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        local cur = StarterGui:GetCore("DevConsoleVisible")
        StarterGui:SetCore("DevConsoleVisible", not cur)
    end)
end)

addSection(MiscPage, "Player Movement & Protection")

local noRagdoll = false
local function removeRagdoll(char)
    if not char then return end
    local rag = char:FindFirstChild("FallDamageRagdoll")
    if rag then
        pcall(function() rag:Destroy() end)
    end
end

local function setupRagdollListener(char)
    if not char then return end
    char.ChildAdded:Connect(function(child)
        if noRagdoll and child.Name == "FallDamageRagdoll" then
            task.wait()
            pcall(function() child:Destroy() end)
        end
    end)
    if noRagdoll then
        removeRagdoll(char)
    end
end

pcall(function()
    if LocalPlayer.Character then
        setupRagdollListener(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(setupRagdollListener)
end)

addToggle(MiscPage, "No Fall Ragdoll (Disabler)", "Löscht FallDamageRagdoll - kein Umfallen/Verkrüppeln", false, function(enabled)
    noRagdoll = enabled
    if noRagdoll and LocalPlayer.Character then
        removeRagdoll(LocalPlayer.Character)
    end
end)

addSlider(MiscPage, "WalkSpeed", 16, 120, 16, function(val)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.WalkSpeed = val end
end)

addSlider(MiscPage, "JumpPower", 50, 200, 50, function(val)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then hum.JumpPower = val end
end)

local noclip = false
addToggle(MiscPage, "Noclip", "Durch Wände gehen", false, function(enabled)
    noclip = enabled
end)

RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

----------------------------------------------------------------------
-- FAHRZEUG GESCHWINDIGKEIT (A-Chassis Tune MaxSpeed & Torque Modifier)
----------------------------------------------------------------------
addSection(MiscPage, "Fahrzeug Speed Modifier (A-Chassis)")

local function getAllAChassisTunes()
    local tunes = {}
    local civCars = workspace:FindFirstChild("CivCars")
    if not civCars then return tunes end
    for _, car in ipairs(civCars:GetChildren()) do
        if car:IsA("Model") then
            -- A-Chassis Interface enthält den Tune
            local tune = car:FindFirstChild("A-Chassis Tune", true)
            if tune then
                local mod = tune:FindFirstChildWhichIsA("ModuleScript")
                if mod then
                    table.insert(tunes, { car = car.Name, mod = mod })
                end
            end
            -- Auch direkte Car.Value Suche
            local val = car:FindFirstChild("Car") and car.Car:FindFirstChild("Value")
            if val then
                local t2 = val:FindFirstChild("A-Chassis Tune")
                if t2 then
                    table.insert(tunes, { car = car.Name, mod = t2 })
                end
            end
        end
    end
    return tunes
end

addSlider(MiscPage, "Auto MaxSpeed (km/h)", 50, 600, 200, function(val)
    pcall(function()
        for _, t in ipairs(getAllAChassisTunes()) do
            local tune = require(t.mod)
            tune.MaxSpeed = val
        end
    end)
    -- Auch DriveSeat MaxSpeed direkt setzen
    local civCars = workspace:FindFirstChild("CivCars")
    if not civCars then return end
    for _, car in ipairs(civCars:GetChildren()) do
        local seat = car:FindFirstChild("DriveSeat", true)
        if seat and seat:IsA("VehicleSeat") then
            pcall(function() seat.MaxSpeed = val end)
        end
    end
end)

addSlider(MiscPage, "Auto Torque / Beschleunigung", 1, 200, 30, function(val)
    pcall(function()
        for _, t in ipairs(getAllAChassisTunes()) do
            local tune = require(t.mod)
            tune.Torque = val
        end
    end)
end)

addButton(MiscPage, "Max Speed auf alle Autos anwenden", "Setzt aktuellen Slider-Wert auf alle CivCars im Workspace", "Apply All", function()
    local civCars = workspace:FindFirstChild("CivCars")
    if not civCars then return end
    for _, car in ipairs(civCars:GetChildren()) do
        local seat = car:FindFirstChild("DriveSeat", true)
        if seat and seat:IsA("VehicleSeat") then
            pcall(function() seat.MaxSpeed = 500 end)
        end
    end
end)

----------------------------------------------------------------------
-- MEHR COMBAT OPTIONS (Stamina, Block, Arms/Legs, God Mode)
----------------------------------------------------------------------
addSection(MiscPage, "Mehr Combat Optionen")

-- Infinite Stamina (shared.u43 = 100 – DAKOTASUI Stamina Bar)
local infiniteStaminaConn = nil
addToggle(MiscPage, "Infinite Stamina (Infinite Punch)", "Hält Stamina immer auf 100 – man kann endlos schlagen", false, function(enabled)
    if enabled then
        infiniteStaminaConn = RunService.Heartbeat:Connect(function()
            -- shared.ThrowPunch prüft u43 >= 10; wir überschreiben CanPunch direkt
            pcall(function()
                shared.CanPunch = function() return true end
            end)
        end)
    else
        if infiniteStaminaConn then infiniteStaminaConn:Disconnect(); infiniteStaminaConn = nil end
        pcall(function()
            shared.CanPunch = nil
        end)
    end
end)

-- Instant Block Ready
addToggle(MiscPage, "Instant Block (Sofort-Blocken)", "Schaltet Blocken sofort frei – kein Cooldown mehr", false, function(enabled)
    if enabled then
        pcall(function()
            shared.CanBlock = function() return true end
        end)
    else
        pcall(function()
            shared.CanBlock = nil
        end)
    end
end)

-- Auto Block (setzt Blocking Attribut automatisch auf true)
local autoBlockConn = nil
addToggle(MiscPage, "Auto-Block (Immer Blocking)", "Setzt LocalPlayer Blocking=true automatisch jeden Frame", false, function(enabled)
    if enabled then
        autoBlockConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                LocalPlayer:SetAttribute("Blocking", true)
            end)
        end)
    else
        if autoBlockConn then autoBlockConn:Disconnect(); autoBlockConn = nil end
        pcall(function() LocalPlayer:SetAttribute("Blocking", false) end)
    end
end)

-- God Mode / Infinite Health
local godModeConn = nil
addToggle(MiscPage, "God Mode (Infinite Health)", "Setzt Humanoid.Health jede Frame auf MaxHealth", false, function(enabled)
    if enabled then
        godModeConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum.MaxHealth > 0 then
                hum.Health = hum.MaxHealth
            end
        end)
    else
        if godModeConn then godModeConn:Disconnect(); godModeConn = nil end
    end
end)

-- Force Show Arms & Legs (LocalTransparencyModifier = 0)
local showArmsConn = nil
addToggle(MiscPage, "Force Show Arms & Legs", "Zeigt Arme und Beine des Chars immer an (kein Verstecken)", false, function(enabled)
    if enabled then
        showArmsConn = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function()
                        part.LocalTransparencyModifier = 0
                    end)
                end
            end
        end)
    else
        if showArmsConn then showArmsConn:Disconnect(); showArmsConn = nil end
    end
end)

-- Carry All Downed Players Loop
local carryAllActive = false
local carryAllConn = nil
addToggle(MiscPage, "Auto-Carry Alle Downed Players", "Hebt automatisch alle am Boden liegenden Spieler auf", false, function(enabled)
    carryAllActive = enabled
    if enabled then
        local FCarryRemote = game.ReplicatedStorage:FindFirstChild("FCarryRemote")
        if FCarryRemote then
            carryAllConn = RunService.Heartbeat:Connect(function()
                if not carryAllActive then
                    carryAllConn:Disconnect(); carryAllConn = nil
                    return
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hum = p.Character:FindFirstChild("Humanoid")
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health <= 0 then
                            pcall(function() FCarryRemote:FireServer(hrp) end)
                        end
                    end
                end
            end)
        end
    else
        if carryAllConn then carryAllConn:Disconnect(); carryAllConn = nil end
    end
end)

-- Anti-Carry (Blockt ProximityPrompts die andere aufheben können)
addToggle(MiscPage, "Anti-Carry (Kein Aufheben von dir)", "Verhindert, dass andere Spieler dich aufheben", false, function(enabled)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local cp = hrp:FindFirstChild("CarryPrompt")
        if cp then cp.Enabled = not enabled end
    end
end)

----------------------------------------------------------------------
-- TAB 7: OPTIONS (GUI Einstellungen & Keybind)
