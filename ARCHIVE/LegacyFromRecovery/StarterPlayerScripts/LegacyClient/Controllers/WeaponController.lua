local WeaponController = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local clientAction = Shared:WaitForChild("ClientAction")
local WeaponEvents = Remotes:WaitForChild("WeaponEvents")
local MatchEvents = Remotes:WaitForChild("MatchEvents")
local ShootEvent = WeaponEvents:WaitForChild("Shoot")
local ReloadEvent = WeaponEvents:WaitForChild("Reload")
local StateChanged = MatchEvents:WaitForChild("StateChanged")
local UIRemotes = Remotes:FindFirstChild("UIRemotes")
local UpdateAmmo = UIRemotes and UIRemotes:FindFirstChild("UpdateAmmo")

local Weapons = ReplicatedStorage:WaitForChild("Weapons")
local Configs = Weapons:WaitForChild("Configs")

local currentWeapon = "Rifle"
local currentState = "Lobby"
local lastFire = 0
local mouseHeld = false
local fireConnection = nil

local slotWeapons = {Primary = "Rifle", Secondary = "Pistol", Melee = nil}

local function getConfig(name)
	local c = Configs:FindFirstChild(name or "Rifle")
	return c and require(c) or {}
end

local function canUseWeapon(player)
	if currentState ~= "Playing" and currentState ~= "Ending" then return false end
	if not player.Character then return false end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health > 0
end

local function expandCrosshair()
	local player = Players.LocalPlayer
	local hud = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HUD")
	if not hud then return end
	local crosshair = hud:FindFirstChild("Crosshair")
	if not crosshair then return end
	for _, part in ipairs(crosshair:GetChildren()) do
		if part:IsA("Frame") then
			local orig = part.Size
			part.Size = UDim2.new(orig.X.Scale, orig.X.Offset + 4, orig.Y.Scale, orig.Y.Offset + 4)
			TweenService:Create(part, TweenInfo.new(0.1), {Size = orig}):Play()
		end
	end
end

local function doShoot()
	local player = Players.LocalPlayer
	if not canUseWeapon(player) then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local config = getConfig(currentWeapon)
	if tick() - lastFire < (config.FireRate or 0.3) then return end
	lastFire = tick()
	local origin = cam.CFrame.Position
	local mouse = player:GetMouse()
	local dir = (mouse.Hit.Position - origin).Unit
	ShootEvent:FireServer(origin, dir, currentWeapon)
	expandCrosshair()
end

function WeaponController.Init()
	local player = Players.LocalPlayer

	StateChanged.OnClientEvent:Connect(function(state)
		currentState = state
	end)

	if UpdateAmmo then
		UpdateAmmo.OnClientEvent:Connect(function(ammo, maxAmmo, reserve)
			local hud = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("HUD")
			if hud then
				local ammoLabel = hud:FindFirstChild("AmmoLabel")
				if ammoLabel then ammoLabel.Text = ammo .. " / " .. (reserve or maxAmmo) end
			end
		end)
	end

	clientAction.Event:Connect(function(action)
		if action == "Fire" then
			doShoot()
		elseif action == "Reload" then
			if canUseWeapon(player) then
				ReloadEvent:FireServer(currentWeapon)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.One then
			currentWeapon = slotWeapons.Primary or "Rifle"
		elseif input.KeyCode == Enum.KeyCode.Two then
			currentWeapon = slotWeapons.Secondary or "Pistol"
		elseif input.KeyCode == Enum.KeyCode.Three and slotWeapons.Melee then
			currentWeapon = slotWeapons.Melee
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			mouseHeld = true
			doShoot()
			local config = getConfig(currentWeapon)
			if config and config.Automatic then
				if fireConnection then fireConnection:Disconnect() fireConnection = nil end
				fireConnection = RunService.Heartbeat:Connect(function()
					if mouseHeld then doShoot() end
				end)
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			if canUseWeapon(player) then
				ReloadEvent:FireServer(currentWeapon)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			mouseHeld = false
			if fireConnection then fireConnection:Disconnect() fireConnection = nil end
		end
	end)
end

return WeaponController
