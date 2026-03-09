local UIController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIRemotes = Remotes:FindFirstChild("UIRemotes")
local MatchEvents = Remotes:FindFirstChild("MatchEvents")
local StateChanged = MatchEvents and MatchEvents:FindFirstChild("StateChanged")
local IntermissionStart = MatchEvents and MatchEvents:FindFirstChild("IntermissionStart")
local UpdateAmmo = UIRemotes and UIRemotes:FindFirstChild("UpdateAmmo")

function UIController.Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	task.wait(0.3)

	local MenuController = require(script.Parent:WaitForChild("MenuController"))
	local ShopController = require(script.Parent:WaitForChild("ShopController"))
	local LoadoutController = require(script.Parent:WaitForChild("LoadoutController"))

	MenuController.Init()
	ShopController.Init()
	LoadoutController.Init()

	local mainUI = playerGui:FindFirstChild("MainUI")
	local hud = playerGui:FindFirstChild("HUD")
	local pages = mainUI and mainUI:FindFirstChild("Pages")
	local mainMenu = pages and pages:FindFirstChild("MainMenu")
	local lobbyMenu = pages and pages:FindFirstChild("LobbyMenu")
	local lobbyCountdown = lobbyMenu and lobbyMenu:FindFirstChild("CountdownLabel")
	local currentState = "Lobby"
	local intermissionToken = 0
	local pendingSpawn = false

	if mainUI and mainUI:GetAttribute("RequestedMatch") == nil then
		mainUI:SetAttribute("RequestedMatch", false)
	end

	local function hideAllPages()
		if not pages then return end
		for _, m in ipairs(pages:GetChildren()) do
			if m:IsA("Frame") then
				m.Visible = false
			end
		end
	end

	local function setMainMenuUI()
		if mainUI and mainUI:GetAttribute("RequestedMatch") then return end
		if mainUI then
			mainUI.Enabled = true
			hideAllPages()
			if mainMenu then mainMenu.Visible = true end
		end
		if hud then hud.Enabled = false end
	end

	local function setLobbyUI(text)
		if mainUI then
			mainUI.Enabled = true
			hideAllPages()
			if lobbyMenu then lobbyMenu.Visible = true end
		end
		if hud then hud.Enabled = false end
		if lobbyCountdown and text then
			lobbyCountdown.Text = text
		end
	end

	local function setMatchUI()
		if mainUI then mainUI.Enabled = false end
		if hud then hud.Enabled = true end
	end

	local function tryEnterMatchUI()
		if currentState ~= "Match" then return false end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			pendingSpawn = false
			if mainUI then mainUI:SetAttribute("RequestedMatch", false) end
			setMatchUI()
			return true
		end
		return false
	end

	setMainMenuUI()

	if StateChanged then
		StateChanged.OnClientEvent:Connect(function(state)
			currentState = state
			if state == "Lobby" then
				if mainUI and mainUI:GetAttribute("RequestedMatch") then
					currentState = "Intermission"
					setLobbyUI("Starting match...")
					return
				end
				intermissionToken += 1
				pendingSpawn = false
				if mainUI then mainUI:SetAttribute("RequestedMatch", false) end
				setMainMenuUI()
			elseif state == "Intermission" then
				if mainUI then mainUI:SetAttribute("RequestedMatch", true) end
				pendingSpawn = false
				setLobbyUI()
			elseif state == "Match" then
				intermissionToken += 1
				pendingSpawn = true
				if mainUI then mainUI:SetAttribute("RequestedMatch", true) end
				setLobbyUI("Loading match...")
				task.delay(6, function()
					if pendingSpawn and currentState == "Match" then
						tryEnterMatchUI()
					end
				end)
			elseif state == "Ending" then
				intermissionToken += 1
				pendingSpawn = false
				if mainUI then mainUI:SetAttribute("RequestedMatch", false) end
				setMatchUI()
			end
		end)
	end

	if IntermissionStart then
		IntermissionStart.OnClientEvent:Connect(function(duration)
			duration = tonumber(duration) or 0
			intermissionToken += 1
			local token = intermissionToken
			currentState = "Intermission"
			pendingSpawn = false
			if mainUI then mainUI:SetAttribute("RequestedMatch", true) end
			for i = duration, 1, -1 do
				if token ~= intermissionToken then return end
				setLobbyUI("Match starts in " .. i)
				task.wait(1)
			end
			if token == intermissionToken then
				setLobbyUI("Loading match...")
			end
		end)
	end

	local playGameEvent = UIRemotes and UIRemotes:FindFirstChild("PlayGame")
	if playGameEvent then
		playGameEvent.OnClientEvent:Connect(function()
			currentState = "Match"
			pendingSpawn = true
			tryEnterMatchUI()
		end)
	end

	task.spawn(function()
		while player.Parent do
			if currentState == "Intermission" or pendingSpawn or (mainUI and mainUI:GetAttribute("RequestedMatch")) then
				if pendingSpawn then
					setLobbyUI("Loading match...")
				else
					setLobbyUI()
				end
			end
			if pendingSpawn and currentState == "Match" then
				tryEnterMatchUI()
			end
			task.wait(0.15)
		end
	end)

	if UpdateAmmo then
		UpdateAmmo.OnClientEvent:Connect(function(ammo, maxAmmo, reserve)
			if hud then
				local ammoLabel = hud:FindFirstChild("AmmoLabel")
				if ammoLabel then ammoLabel.Text = ammo .. " / " .. (reserve or maxAmmo) end
			end
		end)
	end

	player.CharacterAdded:Connect(function(char)
		if currentState == "Match" then
			pendingSpawn = false
			if mainUI then mainUI:SetAttribute("RequestedMatch", false) end
			setMatchUI()
		elseif currentState == "Ending" then
			setMatchUI()
		elseif currentState == "Intermission" or pendingSpawn or (mainUI and mainUI:GetAttribute("RequestedMatch")) then
			if pendingSpawn then
				setLobbyUI("Loading match...")
			else
				setLobbyUI()
			end
		else
			setMainMenuUI()
		end

		local humanoid = char:WaitForChild("Humanoid", 5)
		if humanoid and hud then
			local function updateHealth()
				local healthBar = hud:FindFirstChild("HealthBar")
				if healthBar then
					local fill = healthBar:FindFirstChild("Fill")
					local label = healthBar:FindFirstChild("TextLabel")
					if fill then
						local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
						TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
					end
					if label then
						label.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
					end
				end
			end
			humanoid.HealthChanged:Connect(updateHealth)
			updateHealth()
		end
	end)

	local settingsBtn = hud and hud:FindFirstChild("SettingsButton")
	if settingsBtn then
		settingsBtn.Visible = true
		settingsBtn.MouseButton1Click:Connect(function()
			if mainUI then
				mainUI.Enabled = true
				hideAllPages()
				if pages then
					local settingsMenu = pages:FindFirstChild("SettingsMenu")
					if settingsMenu then settingsMenu.Visible = true end
				end
			end
		end)
	end

	print("UIController Initialized")
end

return UIController
