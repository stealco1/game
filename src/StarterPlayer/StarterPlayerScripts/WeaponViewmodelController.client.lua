local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local gameState = shared:WaitForChild("GameState")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatEvents = remotes:WaitForChild("CombatEvents")
local weaponUpdated = combatEvents:WaitForChild("WeaponUpdated")
local shotConfirmed = combatEvents:WaitForChild("ShotConfirmed")

local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons")
local weaponModels = weaponsFolder:WaitForChild("Models")

local currentWeapon = "Rifle"
local activeViewmodel = nil
local recoilKick = 0
local bobClock = 0

local function isPlaying()
	return gameState.Value == "Playing"
end

local function clearViewmodel()
	if activeViewmodel then
		activeViewmodel:Destroy()
		activeViewmodel = nil
	end
end

local function setViewmodelPartFlags(model)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.CanTouch = false
			obj.CanQuery = false
			obj.CastShadow = false
			obj.Massless = true
		end
	end
end

local function spawnViewmodelForWeapon(weaponName)
	clearViewmodel()
	local source = weaponModels:FindFirstChild(weaponName)
	if not source or not source:IsA("Model") then
		return
	end
	local clone = source:Clone()
	clone.Name = "ActiveViewmodel"
	setViewmodelPartFlags(clone)
	local cam = workspace.CurrentCamera
	if not cam then
		clone:Destroy()
		return
	end
	clone.Parent = cam
	activeViewmodel = clone
end

local function ensureViewmodel()
	if not isPlaying() then
		clearViewmodel()
		return
	end
	if not activeViewmodel or not activeViewmodel.Parent then
		spawnViewmodelForWeapon(currentWeapon)
	end
end

local function getBobbingOffset(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return CFrame.new()
	end
	local moveAmount = math.clamp(humanoid.MoveDirection.Magnitude, 0, 1)
	if moveAmount < 0.01 then
		bobClock = 0
		return CFrame.new()
	end
	bobClock += dt * (7 + (moveAmount * 2.5))
	local x = math.sin(bobClock * 0.9) * 0.015 * moveAmount
	local y = math.abs(math.cos(bobClock)) * 0.018 * moveAmount
	return CFrame.new(x, -y, 0)
end

local function updateViewmodel(dt)
	if not isPlaying() then
		clearViewmodel()
		return
	end
	if not activeViewmodel or not activeViewmodel.Parent then
		ensureViewmodel()
	end
	if not activeViewmodel then return end

	local cam = workspace.CurrentCamera
	if not cam then return end
	local primary = activeViewmodel.PrimaryPart
	if not primary then return end

	recoilKick = recoilKick + (0 - recoilKick) * math.clamp(dt * 12, 0, 1)
	local bob = getBobbingOffset(dt)
	local touchScale = UserInputService.TouchEnabled and 0.75 or 1
	local baseOffset = CFrame.new(0.62, -0.72, -1.32)
	local kickOffset = CFrame.new(0, 0, recoilKick * 0.09 * touchScale) * CFrame.Angles(math.rad(-recoilKick * 4.2 * touchScale), math.rad(recoilKick * 1.4 * touchScale), 0)
	local finalCFrame = cam.CFrame * baseOffset * bob * kickOffset
	activeViewmodel:PivotTo(finalCFrame)
end

weaponUpdated.OnClientEvent:Connect(function(weaponName)
	if typeof(weaponName) ~= "string" then return end
	if weaponName == currentWeapon and activeViewmodel then return end
	currentWeapon = weaponName
	if isPlaying() then
		spawnViewmodelForWeapon(currentWeapon)
	end
end)

shotConfirmed.OnClientEvent:Connect(function(weaponName)
	if typeof(weaponName) == "string" and weaponName == currentWeapon then
		recoilKick = math.clamp(recoilKick + 0.45, 0, 2.5)
	end
end)

gameState:GetPropertyChangedSignal("Value"):Connect(function()
	if isPlaying() then
		ensureViewmodel()
	else
		clearViewmodel()
	end
end)

player.CharacterAdded:Connect(function()
	if isPlaying() then
		task.defer(function()
			ensureViewmodel()
		end)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	updateViewmodel(dt)
end)

ensureViewmodel()
print("WeaponViewmodelController initialized")
