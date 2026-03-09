local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local loadingScreen = playerGui:WaitForChild("LoadingScreen", 8)
local mainUI = playerGui:WaitForChild("MainUI", 8)
local hud = playerGui:WaitForChild("HUD", 8)

if mainUI then mainUI.Enabled = false end
if hud then hud.Enabled = false end

if loadingScreen then
	loadingScreen.Enabled = true
	loadingScreen.DisplayOrder = 100

	local bg = loadingScreen:FindFirstChild("Background")
	local text = loadingScreen:FindFirstChild("LoadingText")

	task.wait(1)
	if bg then TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play() end
	if text then TweenService:Create(text, TweenInfo.new(0.5), {TextTransparency = 1}):Play() end
	task.wait(0.6)

	loadingScreen.Enabled = false
end

if mainUI then
	mainUI.Enabled = true
	local pages = mainUI:FindFirstChild("Pages")
	if pages then
		local hasVisiblePage = false
		for _, page in ipairs(pages:GetChildren()) do
			if page:IsA("Frame") and page.Visible then
				hasVisiblePage = true
				break
			end
		end
		if not hasVisiblePage then
			for _, page in ipairs(pages:GetChildren()) do
				if page:IsA("Frame") then
					page.Visible = (page.Name == "MainMenu")
				end
			end
		end
	end
end
