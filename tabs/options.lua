-- ====================================================================
-- TAB: OPTIONS
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

local OptionsPage = tabPages["Options"]
addSection(OptionsPage, "GUI Einstellungen")

addToggle(OptionsPage, "Interactive Particles", "Schwebende Punkte im Hintergrund an/aus", true, function(enabled)
    particlesEnabled = enabled
    for _, canvas in ipairs(particleContainers) do
        canvas.Visible = enabled
    end
end)

local toggleKey = Enum.KeyCode.RightControl
addButton(OptionsPage, "Toggle Keybind: RightControl", "Drücke RightControl um GUI zu verstecken", "Info", function()
    -- Info Card
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == toggleKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

addButton(OptionsPage, "Unload / Destroy GUI", "Schließt das Skript und entfernt das GUI sauber", "Unload", function()
    ScreenGui:Destroy()
end)
