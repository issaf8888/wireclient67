-- ====================================================================
-- TAB: SHOP
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

local ShopPage = tabPages["Shop"]

local SHOP_ITEMS = {
    { id = "RedCamoGloves",     name = "Red Camo Gloves",     category = "Gloves", badge = "GLOVE" },
    { id = "YelloCamoGloves",   name = "Yellow Camo Gloves",  category = "Gloves", badge = "GLOVE" },
    { id = "PurpleCamoGloves",  name = "Purple Camo Gloves",  category = "Gloves", badge = "GLOVE" },
    { id = "BluCamoGloves",     name = "Blue Camo Gloves",    category = "Gloves", badge = "GLOVE" },
    { id = "PinkCamoGloves",    name = "Pink Camo Gloves",    category = "Gloves", badge = "GLOVE" },
    { id = "CamoGloves",        name = "Camo Gloves",         category = "Gloves", badge = "GLOVE" },
    { id = "BlackGloves",       name = "Black Gloves",        category = "Gloves", badge = "GLOVE" },
    { id = "WhiteGloves",       name = "White Gloves",        category = "Gloves", badge = "GLOVE" },
    { id = "RedGloves",         name = "Red Gloves",          category = "Gloves", badge = "GLOVE" },
    { id = "BluGloves",         name = "Blue Gloves",         category = "Gloves", badge = "GLOVE" },
    { id = "ReddyGloves",       name = "Reddy Gloves",        category = "Gloves", badge = "GLOVE" },

    { id = "Shiesty",           name = "Shiesty Mask",        category = "Masks",  badge = "MASK" },
    { id = "WhiteShiesty",      name = "White Shiesty",       category = "Masks",  badge = "MASK" },
    { id = "CamoShiesty",       name = "Camo Shiesty",        category = "Masks",  badge = "MASK" },
    { id = "YelloShiesty",      name = "Yellow Shiesty",      category = "Masks",  badge = "MASK" },
    { id = "BluShiestyCam",     name = "Blue Camo Shiesty",   category = "Masks",  badge = "MASK" },
    { id = "ShiestyReddy",      name = "Shiesty Reddy",       category = "Masks",  badge = "MASK" },

    { id = "Water",             name = "Water",               category = "Items",  badge = "DRINK" },
    { id = "RawChicken",        name = "Raw Chicken",         category = "Items",  badge = "FOOD" },
    { id = "RawSteak",          name = "Raw Steak",           category = "Items",  badge = "FOOD" },
    { id = "Dice",              name = "Dice",                category = "Items",  badge = "ITEM" },

    -- Exotic Shop Items (aus shop remotes exotic.txt)
    { id = "Sledge Hammer",     name = "Sledge Hammer",       category = "Exotic", badge = "MELEE", isExotic = true },
    { id = "FakeCard",          name = "Fake Card",           category = "Exotic", badge = "CARD",  isExotic = true },
    { id = "Bandage",           name = "Bandage",             category = "Exotic", badge = "MED",   isExotic = true },
    { id = "Screw",             name = "Screw",               category = "Exotic", badge = "TOOL",  isExotic = true },
    { id = "Lemonade",          name = "Lemonade",            category = "Exotic", badge = "DRINK", isExotic = true },
    { id = "RawSteak",          name = "Raw Steak (Exotic)",  category = "Exotic", badge = "FOOD",  isExotic = true },
    { id = "Ice-Fruit Bag",     name = "Ice-Fruit Bag",       category = "Exotic", badge = "DRUG",  isExotic = true },
    { id = "Ice-Fruit Cupz",    name = "Ice-Fruit Cupz",      category = "Exotic", badge = "ITEM",  isExotic = true },
    { id = "FijiWater",         name = "Fiji Water",          category = "Exotic", badge = "DRINK", isExotic = true },
    { id = "FreshWater",        name = "Fresh Water",         category = "Exotic", badge = "DRINK", isExotic = true },

    -- Exotic Ammo & Magazines
    { id = ".Extended",         name = ".Extended Mag",       category = "Ammo",   badge = "MAG",   isExotic = true },
    { id = ".Drum",             name = ".Drum Magazine",      category = "Ammo",   badge = "MAG",   isExotic = true },
    { id = ".FNMag",            name = ".FN Magazine",        category = "Ammo",   badge = "MAG",   isExotic = true },
    { id = ".9mm",              name = ".9mm Ammo",           category = "Ammo",   badge = "AMMO",  isExotic = true },
    { id = "7.62",              name = "7.62 Ammo",           category = "Ammo",   badge = "AMMO",  isExotic = true },
    { id = "5.56",              name = "5.56 Ammo",           category = "Ammo",   badge = "AMMO",  isExotic = true },
    { id = ".10mm",             name = ".10mm Ammo",          category = "Ammo",   badge = "AMMO",  isExotic = true },
    { id = ".Bullets",          name = ".Bullets Refill",     category = "Ammo",   badge = "AMMO",  isExotic = true },
}

local function buyItemRemote(itemData, buyBtn)
    task.spawn(function()
        local origText = buyBtn.Text
        buyBtn.Text = "..."
        local success = pcall(function()
            if typeof(itemData) == "table" and itemData.isExotic then
                local remote = ReplicatedStorage:FindFirstChild("ExoticShopRemote") or ReplicatedStorage:WaitForChild("ExoticShopRemote", 3)
                if remote and remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(itemData.id)
                elseif remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(itemData.id)
                    return true
                end
            else
                local itemId = typeof(itemData) == "table" and itemData.id or itemData
                local remote = ReplicatedStorage:FindFirstChild("ShopRemote") or ReplicatedStorage:WaitForChild("ShopRemote", 3)
                if remote and remote:IsA("RemoteFunction") then
                    return remote:InvokeServer(itemId)
                elseif remote and remote:IsA("RemoteEvent") then
                    remote:FireServer(itemId)
                    return true
                end
            end
        end)

        buyBtn.Text = success and "✓" or "✕"
        buyBtn.TextColor3 = success and Color3.fromRGB(130, 255, 150) or Color3.fromRGB(255, 110, 110)
        task.wait(1)
        buyBtn.Text = origText
        buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
end

addSection(ShopPage, "Shop Remote Store")

-- Filter Leiste
local FilterBar = Instance.new("Frame")
FilterBar.Name = "FilterBar"
FilterBar.BackgroundTransparency = 1
FilterBar.BorderSizePixel = 0
FilterBar.Size = UDim2.new(1, 0, 0, 28)
FilterBar.ZIndex = 4
FilterBar.Parent = ShopPage

local filterListLayout = Instance.new("UIListLayout")
filterListLayout.FillDirection = Enum.FillDirection.Horizontal
filterListLayout.Padding = UDim.new(0, 6)
filterListLayout.Parent = FilterBar

local filterCategories = {
    { id = "All",    title = "All (39)" },
    { id = "Gloves", title = "Gloves" },
    { id = "Masks",  title = "Masks" },
    { id = "Items",  title = "Items" },
    { id = "Exotic", title = "Exotic" },
    { id = "Ammo",   title = "Ammo & Mags" },
}

local shopCards = {}
local filterButtons = {}

local function applyShopFilter(catId)
    for id, fData in pairs(filterButtons) do
        local isActive = (id == catId)
        fData.btn.BackgroundTransparency = isActive and 0.88 or 0.97
        fData.btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    end
    for _, itemData in ipairs(shopCards) do
        itemData.card.Visible = (catId == "All" or itemData.category == catId)
    end
end

for _, fInfo in ipairs(filterCategories) do
    local fBtn = Instance.new("TextButton")
    fBtn.Size = UDim2.new(0, 84, 1, 0)
    fBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fBtn.BackgroundTransparency = (fInfo.id == "All") and 0.88 or 0.97
    fBtn.BorderSizePixel = 0
    fBtn.Font = Enum.Font.GothamMedium
    fBtn.Text = fInfo.title
    fBtn.TextColor3 = (fInfo.id == "All") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
    fBtn.TextSize = 11
    fBtn.AutoButtonColor = false
    fBtn.ZIndex = 4
    fBtn.Parent = FilterBar
    addCorner(fBtn, 6)
    addStroke(fBtn, Color3.fromRGB(255, 255, 255), 1, 0.9)

    filterButtons[fInfo.id] = { btn = fBtn }
    fBtn.MouseButton1Click:Connect(function()
        applyShopFilter(fInfo.id)
    end)
end

for _, item in ipairs(SHOP_ITEMS) do
    local card = Instance.new("Frame")
    card.Name = "Card_" .. item.id
    card.Size = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.97
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = ShopPage
    addCorner(card, 8)
    addStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.94)

    local badgeLabel = Instance.new("TextLabel")
    badgeLabel.AnchorPoint = Vector2.new(0, 0.5)
    badgeLabel.Position = UDim2.new(0, 10, 0.5, 0)
    badgeLabel.Size = UDim2.new(0, 52, 0, 20)
    badgeLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    badgeLabel.BackgroundTransparency = 0.94
    badgeLabel.BorderSizePixel = 0
    badgeLabel.Font = Enum.Font.GothamMedium
    badgeLabel.Text = item.badge
    badgeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    badgeLabel.TextSize = 9
    badgeLabel.ZIndex = 5
    badgeLabel.Parent = card
    addCorner(badgeLabel, 4)
    addStroke(badgeLabel, Color3.fromRGB(255, 255, 255), 1, 0.92)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 70, 0, 6)
    nameLabel.Size = UDim2.new(1, -165, 0, 16)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.Text = item.name
    nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = card

    local subLabel = Instance.new("TextLabel")
    subLabel.BackgroundTransparency = 1
    subLabel.Position = UDim2.new(0, 70, 0, 22)
    subLabel.Size = UDim2.new(1, -165, 0, 14)
    subLabel.Font = Enum.Font.Gotham
    subLabel.Text = item.id
    subLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    subLabel.TextSize = 10
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.ZIndex = 5
    subLabel.Parent = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.AnchorPoint = Vector2.new(1, 0.5)
    buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
    buyBtn.Size = UDim2.new(0, 62, 0, 26)
    buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.BackgroundTransparency = 0.94
    buyBtn.BorderSizePixel = 0
    buyBtn.Font = Enum.Font.GothamMedium
    buyBtn.Text = "Buy"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.TextSize = 12
    buyBtn.AutoButtonColor = false
    buyBtn.ZIndex = 5
    buyBtn.Parent = card
    addCorner(buyBtn, 6)
    addStroke(buyBtn, Color3.fromRGB(255, 255, 255), 1, 0.88)

    buyBtn.MouseButton1Click:Connect(function()
        buyItemRemote(item, buyBtn)
    end)

    table.insert(shopCards, { card = card, category = item.category })
end

----------------------------------------------------------------------
-- TAB 5: FARM (Hospital Beds & Leveling)
