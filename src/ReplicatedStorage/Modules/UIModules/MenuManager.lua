local MenuManager = {}
local Players = game:GetService("Players")

function MenuManager.ShowMenu(player)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local mainMenu = playerGui:FindFirstChild("MainMenu")
	if mainMenu then
		mainMenu.Enabled = true
		mainMenu:FindFirstChild("MainFrame").GroupTransparency = 0
	end
end

function MenuManager.HideMenu(player)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local mainMenu = playerGui:FindFirstChild("MainMenu")
	if mainMenu then
		mainMenu.Enabled = false
	end
end

return MenuManager
