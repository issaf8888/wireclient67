-- ====================================================================
-- TAB: MONEY
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

----------------------------------------------------------------------
-- TAB 1: MONEY
----------------------------------------------------------------------
local MoneyPage = tabPages["Money"]
addSection(MoneyPage, "Geld & Auto-Collect")

local autoCash = false
addToggle(MoneyPage, "Auto-Collect Dropped Cash", "Sammelt automatisch Geld am Boden ein", false, function(enabled)
    autoCash = enabled
    while autoCash do
        pcall(function()
            for _, item in ipairs(workspace:GetDescendants()) do
                if not autoCash then break end
                if item:IsA("ProximityPrompt") and (item.ActionText:lower():find("take") or item.ActionText:lower():find("money") or item.ActionText:lower():find("cash") or item.ObjectText:lower():find("cash")) then
                    fireproximityprompt(item)
                end
            end
        end)
        task.wait(1.5)
    end
end)

addButton(MoneyPage, "Instant Cash Sweep", "Scannt ProximityPrompts im Umkreis", "Collect", function()
    for _, item in ipairs(workspace:GetDescendants()) do
        if item:IsA("ProximityPrompt") then
            local text = (item.ActionText .. " " .. item.ObjectText):lower()
            if text:find("cash") or text:find("money") or text:find("take") then
                pcall(function() fireproximityprompt(item) end)
            end
        end
    end
end)

local atmRobbery = false
addToggle(MoneyPage, "ATM Robbery Loop", "Automatische ATM-Interaktion & Geldabhebung", false, function(enabled)
    atmRobbery = enabled
    while atmRobbery do
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if not atmRobbery then break end
                if obj:IsA("ProximityPrompt") then
                    local text = (obj.ActionText .. " " .. obj.ObjectText):lower()
                    if text:find("atm") or text:find("rob") or text:find("withdraw") or text:find("hack") then
                        fireproximityprompt(obj, 0)
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

----------------------------------------------------------------------
-- CASHAPP & BANK REMOTES (aus --cash vielleicht--.txt & bank actions.txt)
----------------------------------------------------------------------
addSection(MoneyPage, "Bank & CashApp Remotes")

local function getBankAction()
    return ReplicatedStorage:FindFirstChild("BankAction") or (pcall(function() return ReplicatedStorage:WaitForChild("BankAction", 2) end) and ReplicatedStorage:FindFirstChild("BankAction"))
end

local function getBankProcess()
    return ReplicatedStorage:FindFirstChild("BankProcessRemote") or (pcall(function() return ReplicatedStorage:WaitForChild("BankProcessRemote", 2) end) and ReplicatedStorage:FindFirstChild("BankProcessRemote"))
end

addButton(MoneyPage, "Instant Deposit ($10,000)", "Zahlt $10.000 sofort aufs Bankkonto ein (Remote Bypass)", "Deposit", function()
    local bankAction = getBankAction()
    if bankAction then
        bankAction:FireServer("depo", "10000")
    end
end)

local autoBankDeposit = false
addToggle(MoneyPage, "Auto-Deposit Bank Loop", "Zahlt fortlaufend $10.000 ein (sichert Cash vor Tod/Raub)", false, function(enabled)
    autoBankDeposit = enabled
    while autoBankDeposit do
        pcall(function()
            local bankAction = getBankAction()
            if bankAction then
                bankAction:FireServer("depo", "10000")
            end
        end)
        task.wait(1.5)
    end
end)

addButton(MoneyPage, "Drop $10,000 Cash", "Droppt sofort $10.000 Bargeld am Boden vor dir", "Drop 10k", function()
    local bankProcess = getBankProcess()
    if bankProcess then
        bankProcess:InvokeServer("Drop", "10000")
    end
end)

addButton(MoneyPage, "Drop $5,000 Cash", "Droppt sofort $5.000 Bargeld am Boden vor dir", "Drop 5k", function()
    local bankProcess = getBankProcess()
    if bankProcess then
        bankProcess:InvokeServer("Drop", "5000")
    end
end)

local autoCashDrop = false
addToggle(MoneyPage, "Auto Cash-Drop Spammer ($10k)", "Droppt alle 0.5s $10.000 Cash am laufenden Band", false, function(enabled)
    autoCashDrop = enabled
    while autoCashDrop do
        pcall(function()
            local bankProcess = getBankProcess()
            if bankProcess then
                bankProcess:InvokeServer("Drop", "10000")
            end
        end)
        task.wait(0.5)
    end
end)

addInputCard(MoneyPage, "Custom Cash Drop", "Eigenen Betrag droppen (z.B. 10000)", "Amount...", "Drop", function(text)
    local num = tonumber(text)
    if num and num > 0 then
        local bankProcess = getBankProcess()
        if bankProcess then
            bankProcess:InvokeServer("Drop", tostring(num))
        end
    end
end)

addButton(MoneyPage, "Send $10k to Nearest Player", "Überweist $10.000 an den nächstgelegenen Spieler", "Send 10k", function()
    local bankProcess = getBankProcess()
    if not bankProcess then return end
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end

    local nearestPlayer = nil
    local nearestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myHrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestPlayer = p
            end
        end
    end

    if nearestPlayer then
        bankProcess:InvokeServer("Send", "10000", nearestPlayer.Name)
    end
end)

addInputCard(MoneyPage, "CashApp Wire Transfer", "Format: 'Spielername, Betrag' (z.B. Player1, 10000)", "Player, Amount", "Send", function(text)
    local bankProcess = getBankProcess()
    if not bankProcess or not text or text == "" then return end

    local targetName, amountStr = text:match("^%s*([^,]+)%s*,%s*([%d]+)%s*$")
    if not targetName or not amountStr then
        targetName, amountStr = text:match("^%s*(%S+)%s+([%d]+)%s*$")
    end

    if targetName and amountStr then
        local foundName = targetName
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():sub(1, #targetName) == targetName:lower() or p.DisplayName:lower():sub(1, #targetName) == targetName:lower() then
                foundName = p.Name
                break
            end
        end
        bankProcess:InvokeServer("Send", amountStr, foundName)
    end
end)

addSection(MoneyPage, "Ice-Fruit & Dupe Exploits")

addButton(MoneyPage, "LTK Hub 999x Ice-Fruit Dupe", "Spamt IceFruit Sell 999x & stellt UI/Position wieder her", "Dupe", function()
    local sellPart = workspace:FindFirstChild("IceFruit Sell")
    local prompt = sellPart and (sellPart:FindFirstChildWhichIsA("ProximityPrompt", true) or sellPart:FindFirstChild("ProximityPrompt"))
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local oldPos = hrp and hrp.CFrame

    if sellPart and hrp then
        hrp.CFrame = sellPart.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.2)
    end

    if prompt then
        for i = 1, 999 do
            pcall(function() fireproximityprompt(prompt, 0) end)
        end
    end

    task.wait(1)
    if hrp and oldPos then
        hrp.CFrame = oldPos
    end

    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, gName in ipairs({"Hunger", "HealthGui", "Run", "SleepGui", "MoneyGui", "NewMoneyGui"}) do
                local g = pg:FindFirstChild(gName)
                if g then g.Enabled = true end
            end
        end
    end)
end)

local iceFruitAutoFarm = false
addToggle(MoneyPage, "Auto Ice-Fruit Cook & Sell", "Kauft Zutaten, kocht am Topf & verkauft vollautomatisch", false, function(enabled)
    iceFruitAutoFarm = enabled
    while iceFruitAutoFarm do
        pcall(function()
            -- 1. Buy Supplies via ExoticShopRemote
            local exoticRemote = ReplicatedStorage:FindFirstChild("ExoticShopRemote")
            local items = {"Ice-Fruit Bag", "Ice-Fruit Cupz", "FijiWater", "FreshWater"}
            if exoticRemote then
                for _, item in ipairs(items) do
                    if not iceFruitAutoFarm then return end
                    pcall(function() exoticRemote:InvokeServer(item) end)
                    task.wait(0.3)
                end
            end

            -- 2. Find Cooking Pot
            local potsFolder = workspace:FindFirstChild("CookingPots")
            local pot = nil
            if potsFolder then
                for _, p in ipairs(potsFolder:GetChildren()) do
                    if p:IsA("Model") then
                        local ownerTag = p:FindFirstChild("Owner", true)
                        local progress = p:FindFirstChild("CookPart") and p.CookPart:FindFirstChild("Steam") and p.CookPart.Steam:FindFirstChild("LoadUI")
                        if (not ownerTag or not ownerTag.Value) and (not progress or not progress.Enabled) then
                            pot = p
                            break
                        end
                    end
                end
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            local bp = LocalPlayer:FindFirstChild("Backpack")

            if pot and hrp and hum then
                local cookPart = pot:FindFirstChild("CookPart") or pot:FindFirstChildWhichIsA("BasePart")
                local cookPrompt = cookPart and cookPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                local cookProgress = cookPart and cookPart:FindFirstChild("Steam") and cookPart.Steam:FindFirstChild("LoadUI")

                if cookPart and cookPrompt then
                    hrp.CFrame = cookPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.3)
                    pcall(function() fireproximityprompt(cookPrompt, 0) end)
                    task.wait(0.3)

                    local cookOrder = {"FijiWater", "FreshWater", "Ice-Fruit Bag"}
                    for _, name in ipairs(cookOrder) do
                        if not iceFruitAutoFarm then return end
                        local tool = (char and char:FindFirstChild(name)) or (bp and bp:FindFirstChild(name))
                        if tool then
                            hum:EquipTool(tool)
                            task.wait(0.4)
                            pcall(function() fireproximityprompt(cookPrompt, 0) end)
                            task.wait(0.4)
                        end
                    end

                    -- Wait for cooking progress
                    if cookProgress then
                        local timeout = 0
                        while iceFruitAutoFarm and cookProgress.Enabled and timeout < 25 do
                            task.wait(0.5)
                            timeout = timeout + 0.5
                        end
                    else
                        task.wait(6)
                    end

                    -- Equip cupz
                    local cupz = (char and char:FindFirstChild("Ice-Fruit Cupz")) or (bp and bp:FindFirstChild("Ice-Fruit Cupz"))
                    if cupz then
                        hum:EquipTool(cupz)
                        task.wait(0.4)
                        pcall(function() fireproximityprompt(cookPrompt, 0) end)
                        task.wait(0.5)
                    end
                end
            end

            -- 3. Teleport to IceFruit Sell and sell
            local sellPart = workspace:FindFirstChild("IceFruit Sell")
            if sellPart and hrp then
                local sellPrompt = sellPart:FindFirstChildWhichIsA("ProximityPrompt", true) or sellPart:FindFirstChild("ProximityPrompt")
                hrp.CFrame = sellPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.3)
                if sellPrompt then
                    for _ = 1, 500 do
                        if not iceFruitAutoFarm then break end
                        pcall(function() fireproximityprompt(sellPrompt, 0) end)
                    end
                end
            end
        end)
        task.wait(2)
    end
end)

addSection(MoneyPage, "StudioPay Cash Farm")

local studioFarmActive = false
addToggle(MoneyPage, "Studio Cash Farm Loop", "Teleportiert zu StudioPay 1-3 & stiehlt Geld automatisch", false, function(enabled)
    studioFarmActive = enabled
    while studioFarmActive do
        pcall(function()
            local studioPay = workspace:FindFirstChild("StudioPay")
            local moneyFolder = studioPay and studioPay:FindFirstChild("Money")
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if moneyFolder and hrp then
                for i = 1, 3 do
                    if not studioFarmActive then break end
                    local stack = moneyFolder:FindFirstChild("StudioPay" .. i)
                    if stack then
                        local prompt = stack:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            local part = stack:IsA("BasePart") and stack or stack:FindFirstChildWhichIsA("BasePart")
                            if part then
                                hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.2)
                                local tries = 0
                                while studioFarmActive and prompt.Enabled and tries < 20 do
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

addButton(MoneyPage, "Teleport to StudioPay", "Teleportiert direkt zu den StudioPay Geldstapeln", "Teleport", function()
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
-- TAB 2: AIM (Mit Game-Remotes: ChangeMagAndAmmo)
