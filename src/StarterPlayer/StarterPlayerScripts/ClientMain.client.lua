local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local gameState = shared:WaitForChild("GameState")

local clientAction = shared:FindFirstChild("ClientAction")
if not clientAction then
	clientAction = Instance.new("BindableEvent")
	clientAction.Name = "ClientAction"
	clientAction.Parent = shared
end

local forceMouseUnlock = false

local function isMenuMouseUnlockForced()
	return forceMouseUnlock or player:GetAttribute("ForceMenuMouseUnlock") == true or player:GetAttribute("IsInMenu") == true
end
local function setHeadVisibility(character, hideHead)
	if not character then return end
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name == "Head" then
				obj.LocalTransparencyModifier = hideHead and 1 or 0
				obj.CastShadow = not hideHead
			elseif obj.Parent and obj.Parent:IsA("Accessory") and obj.Name ~= "Handle" then
				obj.LocalTransparencyModifier = hideHead and 1 or 0
				obj.CastShadow = not hideHead
			end
		end
	end
end

local function applyMouseSensitivity()
	local sensitivity = tonumber(player:GetAttribute("MouseSensitivity"))
	if sensitivity == nil then
		sensitivity = 1
		player:SetAttribute("MouseSensitivity", sensitivity)
	end
	sensitivity = math.clamp(sensitivity, 0.2, 2.5)
	pcall(function()
		UserInputService.MouseDeltaSensitivity = sensitivity
	end)
end

local function applyCameraState()
	local isPlaying = gameState.Value == "Playing"
	local inMenu = player:GetAttribute("IsInMenu") == true
	local switching = player:GetAttribute("TeamSwitchPending") == true
	local isActivePlaying = isPlaying and (not inMenu) and (not switching)
	local character = player.Character
	applyMouseSensitivity()

	local menuUnlock = isMenuMouseUnlockForced() or inMenu or switching
	local shouldLockMouse = isActivePlaying and (not UserInputService.TouchEnabled) and (not menuUnlock)

	if isActivePlaying and not menuUnlock then
		pcall(function() player.CameraMode = Enum.CameraMode.LockFirstPerson end)
		pcall(function() player.CameraMinZoomDistance = 0.5 end)
		pcall(function() player.CameraMaxZoomDistance = 0.5 end)
		pcall(function() player.AutoJumpEnabled = false end)
		if shouldLockMouse then
			pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
			pcall(function() UserInputService.MouseIconEnabled = false end)
		else
			pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
			pcall(function() UserInputService.MouseIconEnabled = true end)
		end
		setHeadVisibility(character, true)
	else
		pcall(function() player.CameraMode = Enum.CameraMode.Classic end)
		pcall(function() player.CameraMinZoomDistance = 0.5 end)
		pcall(function() player.CameraMaxZoomDistance = 24 end)
		pcall(function() player.AutoJumpEnabled = false end)
		pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
		pcall(function() UserInputService.MouseIconEnabled = true end)
		setHeadVisibility(character, false)
		if not isPlaying then
			forceMouseUnlock = false
			if player:GetAttribute("ForceMenuMouseUnlock") == true then
				player:SetAttribute("ForceMenuMouseUnlock", false)
			end
		end
	end

	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function onCharacterAdded(character)
	applyCameraState()
	character.DescendantAdded:Connect(function(desc)
		if desc:IsA("BasePart") and desc.Name == "Head" then
			setHeadVisibility(character, gameState.Value == "Playing" and not isMenuMouseUnlockForced())
		end
	end)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

gameState:GetPropertyChangedSignal("Value"):Connect(function()
	if gameState.Value ~= "Playing" then
		forceMouseUnlock = false
		player:SetAttribute("ForceMenuMouseUnlock", false)
	end
	applyCameraState()
	task.delay(0.15, applyCameraState)
end)

player:GetAttributeChangedSignal("MouseSensitivity"):Connect(function()
	applyMouseSensitivity()
end)

player:GetAttributeChangedSignal("ForceMenuMouseUnlock"):Connect(function()
	applyCameraState()
end)

for _, attr in ipairs({"IsInMenu", "TeamSwitchPending"}) do
	player:GetAttributeChangedSignal(attr):Connect(function()
		applyCameraState()
	end)
end

clientAction.Event:Connect(function(action)
	if action == "ForceUnlockMouse" then
		forceMouseUnlock = true
		applyCameraState()
	elseif action == "ReleaseMouseOverride" then
		forceMouseUnlock = false
		applyCameraState()
	end
end)

applyCameraState()
print("ClientMain initialized")
