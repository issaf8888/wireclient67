-- ====================================================================
-- TAB: FARM
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

local FarmPage = tabPages["Farm"]
addSection(FarmPage, "Hospital & Safe Farm")

addButton(FarmPage, "Teleport to Hospital Bed", "Nutzt HospitalBeds aus dem Spiel für Instant Heal", "Teleport", function()
    local bedsFolder = workspace:FindFirstChild("HospitalBeds")
    if bedsFolder and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _, bed in ipairs(bedsFolder:GetDescendants()) do
            if bed:IsA("BasePart") and bed.Name == "Bed" then
                LocalPlayer.Character.HumanoidRootPart.CFrame = bed.CFrame + Vector3.new(0, 3, 0)
                break
            end
        end
    end
end)

addToggle(FarmPage, "Auto-Heal on Low HP", "Teleportiert ins Krankenhausbett bei unter 25% HP", false, function(enabled)
    local active = enabled
    while active do
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and hum.Health < 25 and hum.Health > 0 then
                local bedsFolder = workspace:FindFirstChild("HospitalBeds")
                if bedsFolder then
                    for _, bed in ipairs(bedsFolder:GetDescendants()) do
                        if bed:IsA("BasePart") and bed.Name == "Bed" then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = bed.CFrame + Vector3.new(0, 3, 0)
                            task.wait(5)
                            break
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

addSection(FarmPage, "Interaktionen & Proximity Prompts")

local instantPrompts = false
local promptCache = {}

local function applyPromptInstant(prompt)
    if prompt:IsA("ProximityPrompt") then
        if promptCache[prompt] == nil then
            promptCache[prompt] = prompt.HoldDuration
        end
        prompt.HoldDuration = 0
    end
end

local function restorePrompts()
    for prompt, duration in pairs(promptCache) do
        if prompt and prompt.Parent then
            pcall(function() prompt.HoldDuration = duration end)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if instantPrompts and obj:IsA("ProximityPrompt") then
        task.wait()
        applyPromptInstant(obj)
    end
end)

addToggle(FarmPage, "Instant Proximity Prompts", "Setzt HoldDuration aller Prompts auf 0s (Kein Halten nötig)", false, function(enabled)
    instantPrompts = enabled
    if instantPrompts then
        for _, obj in ipairs(workspace:GetDescendants()) do
            applyPromptInstant(obj)
        end
    else
        restorePrompts()
    end
end)

addSection(FarmPage, "Studio Cash Farm (StudioPay)")

local studioFarmActive2 = false
addToggle(FarmPage, "Studio Cash Farm Loop", "Teleportiert zu StudioPay 1-3 & stiehlt Geld automatisch", false, function(enabled)
    studioFarmActive2 = enabled
    while studioFarmActive2 do
        pcall(function()
            local studioPay = workspace:FindFirstChild("StudioPay")
            local moneyFolder = studioPay and studioPay:FindFirstChild("Money")
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if moneyFolder and hrp then
                for i = 1, 3 do
                    if not studioFarmActive2 then break end
                    local stack = moneyFolder:FindFirstChild("StudioPay" .. i)
                    if stack then
                        local prompt = stack:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            local part = stack:IsA("BasePart") and stack or stack:FindFirstChildWhichIsA("BasePart")
                            if part then
                                hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.2)
                                local tries = 0
                                while studioFarmActive2 and prompt.Enabled and tries < 20 do
                                    pcall(function() fireproximityprompt(prompt, 0) end)
                                    tries = tries + 1
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

addButton(FarmPage, "Teleport to StudioPay", "Teleportiert direkt zu den StudioPay Geldstapeln", "Teleport", function()
    local studioPay = workspace:FindFirstChild("StudioPay")
    local moneyFolder = studioPay and studioPay:FindFirstChild("Money")
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if moneyFolder and hrp then
        local stack = moneyFolder:FindFirstChild("StudioPay1") or moneyFolder:FindFirstChildWhichIsA("Model")
        local part = stack and (stack:IsA("BasePart") and stack or stack:FindFirstChildWhichIsA("BasePart"))
        if part then
            hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

----------------------------------------------------------------------
-- TAB 6: MISC (ToolReplicator, BeamToggle, PlayAudio)
