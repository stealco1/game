local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait()

local critical = {"MainUI", "HUD", "LoadingScreen"}
for _, name in ipairs(critical) do
	if not playerGui:FindFirstChild(name) then
		local template = StarterGui:FindFirstChild(name)
		if template then
			local clone = template:Clone()
			clone.ResetOnSpawn = false
			clone.Parent = playerGui
		end
	end
end

local loadingScreen = playerGui:FindFirstChild("LoadingScreen")
local mainUI = playerGui:FindFirstChild("MainUI")
local hud = playerGui:FindFirstChild("HUD")

if loadingScreen then
	loadingScreen.ResetOnSpawn = false
	loadingScreen.Enabled = true
end
if mainUI then
	mainUI.ResetOnSpawn = false
	mainUI.Enabled = false
end
if hud then
	hud.ResetOnSpawn = false
	hud.Enabled = false
end
