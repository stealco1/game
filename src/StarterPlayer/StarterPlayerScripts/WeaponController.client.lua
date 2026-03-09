local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local clientAction = shared:WaitForChild("ClientAction")
local gameState = shared:WaitForChild("GameState")
local weaponData = require(shared:WaitForChild("WeaponData"))

local weaponEvents = remotes:WaitForChild("WeaponEvents")
local combatEvents = remotes:WaitForChild("CombatEvents")

local shootEvent = weaponEvents:WaitForChild("Shoot")
local reloadEvent = weaponEvents:WaitForChild("Reload")
local equipEvent = weaponEvents:WaitForChild("Equip")
local setCombatStateEvent = weaponEvents:WaitForChild("SetCombatState", 5)

local currentWeapon = "Rifle"
local currentAmmo = 0
local currentReserve = 0
local firingHeld = false
local autoConn = nil

local BASE_WALK_SPEED = 17
local CROUCH_WALK_SPEED = 11.25
local CROUCH_CAMERA_OFFSET = -1.2

local state = {
	WeaponState = "Idle",
	IsCrouching = false,
	IsReloading = false,
	IsSwapping = false,
	LastLocalShot = 0,
	LastStatePush = 0,
	CrosshairGap = 6,
}

local recoil = {
	Spread = 0,
}

local crosshairParts = {
	Root = nil,
	Top = nil,
	Bottom = nil,
	Left = nil,
	Right = nil,
	Center = nil,
}

local sounds = {
	Shot = nil,
}

local function inPlayableState()
	return gameState.Value == "Playing"
		and player:GetAttribute("IsInMatch") == true
		and player:GetAttribute("IsInMenu") ~= true
end

local function getCharacterHumanoidRoot()
	local character = player.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function getWeaponConfig(name)
	local raw = weaponData[name] or weaponData.Rifle or {}
	local fireMode = raw.FireMode
	if type(fireMode) ~= "string" then
		fireMode = raw.Automatic and "Auto" or "Semi"
	end
	return {
		Raw = raw,
		FireMode = fireMode,
		BurstCount = math.max(2, math.floor(tonumber(raw.BurstCount) or 3)),
		Automatic = fireMode == "Auto",
		FireInterval = tonumber(raw.FireRate) or 0.2,
		BaseSpread = tonumber(raw.BaseSpread) or tonumber(raw.Spread) or 1,
		MoveSpread = tonumber(raw.MoveSpread) or 1.1,
		AirSpread = tonumber(raw.AirSpread) or 1.8,
		RecoilSpreadStep = tonumber(raw.RecoilSpread) or 0.32,
		RecoilRecoverySpeed = tonumber(raw.RecoilRecoverySpeed) or 6,
		IsMelee = raw.IsMelee == true,
	}
end

local function ensureShotSound()
	if sounds.Shot and sounds.Shot.Parent then
		return sounds.Shot
	end
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local s = Instance.new("Sound")
	s.Name = "ClientShotTick"
	s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	s.Volume = 0.09
	s.PlaybackSpeed = 1.18
	s.RollOffMaxDistance = 20
	s.Parent = cam
	sounds.Shot = s
	return s
end

local function pushCombatState(force)
	if not setCombatStateEvent then return end
	local now = os.clock()
	if not force and now - state.LastStatePush < 0.06 then
		return
	end
	state.LastStatePush = now
	setCombatStateEvent:FireServer({
		State = state.WeaponState,
		Sprinting = false,
		Crouching = state.IsCrouching,
	})
end

local function setWeaponState(nextState)
	if state.WeaponState == nextState then return end
	state.WeaponState = nextState
	pushCombatState(false)
end

local function updateHudAmmo()
	local pg = player:FindFirstChild("PlayerGui")
	local hud = pg and pg:FindFirstChild("HUD")
	if not hud then return end
	local ammoLabel = hud:FindFirstChild("AmmoLabel")
	local weaponName = hud:FindFirstChild("WeaponName")
	local data = weaponData[currentWeapon]
	local isMelee = data and data.IsMelee == true
	if ammoLabel then
		ammoLabel.Visible = not isMelee
		if not isMelee then
			ammoLabel.Text = tostring(currentAmmo) .. " / " .. tostring(currentReserve)
		end
	end
	if weaponName then
		weaponName.Text = currentWeapon
	end
end

local function updateHudHealth(h, maxH)
	local pg = player:FindFirstChild("PlayerGui")
	local hud = pg and pg:FindFirstChild("HUD")
	if not hud then return end
	local bar = hud:FindFirstChild("HealthBar")
	if not bar then return end
	local fill = bar:FindFirstChild("Fill")
	local label = bar:FindFirstChild("TextLabel")
	if fill then
		local ratio = 0
		if maxH and maxH > 0 then ratio = math.clamp(h / maxH, 0, 1) end
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end
	if label then
		label.Text = tostring(math.floor(h or 0)) .. " / " .. tostring(math.floor(maxH or 0))
	end
end

local function resolveCrosshairParts()
	local pg = player:FindFirstChild("PlayerGui")
	local hud = pg and pg:FindFirstChild("HUD")
	local crosshair = hud and hud:FindFirstChild("Crosshair")
	if not crosshair or not crosshair:IsA("Frame") then
		return
	end
	crosshairParts.Root = crosshair
	crosshairParts.Top = nil
	crosshairParts.Bottom = nil
	crosshairParts.Left = nil
	crosshairParts.Right = nil
	crosshairParts.Center = nil

	for _, child in ipairs(crosshair:GetChildren()) do
		if child:IsA("Frame") then
			local x = child.Position.X.Scale
			local y = child.Position.Y.Scale
			if math.abs(x - 0.5) < 0.02 and math.abs(y - 0.5) < 0.02 then
				crosshairParts.Center = child
			elseif math.abs(x - 0.5) < 0.02 and y < 0.5 then
				crosshairParts.Top = child
			elseif math.abs(x - 0.5) < 0.02 and y > 0.5 then
				crosshairParts.Bottom = child
			elseif x < 0.5 and math.abs(y - 0.5) < 0.02 then
				crosshairParts.Left = child
			elseif x > 0.5 and math.abs(y - 0.5) < 0.02 then
				crosshairParts.Right = child
			end
		end
	end
end

local function updateCrosshair(gap)
	if not crosshairParts.Root or not crosshairParts.Root.Parent then
		resolveCrosshairParts()
	end
	if not crosshairParts.Root then return end
	if crosshairParts.Top then
		crosshairParts.Top.Position = UDim2.new(0.5, -1, 0, -(gap + 8))
	end
	if crosshairParts.Bottom then
		crosshairParts.Bottom.Position = UDim2.new(0.5, -1, 1, gap)
	end
	if crosshairParts.Left then
		crosshairParts.Left.Position = UDim2.new(0, -(gap + 8), 0.5, -1)
	end
	if crosshairParts.Right then
		crosshairParts.Right.Position = UDim2.new(1, gap, 0.5, -1)
	end
end

local function getAimDirection()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local viewport = cam.ViewportSize
	local ray = cam:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	if ray.Direction.Magnitude < 0.01 then
		return cam.CFrame.LookVector
	end
	return ray.Direction.Unit
end

local function performClientRaycast(origin, direction, range)
	local character = player.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = character and {character} or {}
	return workspace:Raycast(origin, direction * range, params)
end

local function canStandUp()
	if not state.IsCrouching then return true end
	local _, _, root = getCharacterHumanoidRoot()
	if not root then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}
	local result = workspace:Raycast(root.Position, Vector3.new(0, 4.5, 0), params)
	return result == nil
end

local function setCrouchEnabled(enabled)
	enabled = enabled == true
	if enabled == state.IsCrouching then return end
	if enabled then
		state.IsCrouching = true
		setWeaponState("Crouching")
	else
		if not canStandUp() then return end
		state.IsCrouching = false
		setWeaponState("Idle")
	end
	pushCombatState(true)
end

local function getLiveSpread(config)
	local _, humanoid, root = getCharacterHumanoidRoot()
	local moveMag = 0
	local airborne = false
	if humanoid then
		moveMag = humanoid.MoveDirection.Magnitude
		airborne = humanoid.FloorMaterial == Enum.Material.Air
	elseif root then
		local planar = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
		moveMag = math.clamp(planar / BASE_WALK_SPEED, 0, 1)
	end
	local spread = config.BaseSpread + (config.MoveSpread * moveMag) + (airborne and config.AirSpread or 0) + recoil.Spread
	if state.IsCrouching then
		spread *= 0.88
	end
	return spread, airborne
end

local function playShotFeedback()
	local shot = ensureShotSound()
	if shot then
		shot.TimePosition = 0
		shot:Play()
	end
end

local function canShootNow(config)
	if not inPlayableState() then return false end
	local _, humanoid = getCharacterHumanoidRoot()
	if not humanoid or humanoid.Health <= 0 then return false end
	if state.IsReloading then return false end
	if state.IsSwapping then return false end
	local now = os.clock()
	if now - state.LastLocalShot < config.FireInterval then return false end
	return true
end

local function sendShoot()
	local config = getWeaponConfig(currentWeapon)
	if not canShootNow(config) then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local direction = getAimDirection()
	if not direction then return end

	state.LastLocalShot = os.clock()
	if state.IsCrouching then
		setWeaponState("Crouching")
	else
		setWeaponState("Firing")
	end

	recoil.Spread = math.clamp(recoil.Spread + config.RecoilSpreadStep, 0, 7)
	playShotFeedback()

	local origin = cam.CFrame.Position
	local predicted = performClientRaycast(origin, direction, config.Raw.Range or 500)
	if predicted then
		shootEvent:FireServer(origin, direction, predicted.Position)
	else
		shootEvent:FireServer(origin, direction)
	end
end

local function switchWeapon()
	state.IsSwapping = true
	setWeaponState("Swapping")
	equipEvent:FireServer("Switch")
	task.delay(0.3, function()
		if state.IsSwapping then
			state.IsSwapping = false
			if state.IsCrouching then
				setWeaponState("Crouching")
			else
				setWeaponState("Idle")
			end
		end
	end)
end

local function tryBurstFire()
	local config = getWeaponConfig(currentWeapon)
	local count = config.BurstCount
	for i = 1, count do
		if not firingHeld and i > 1 then break end
		sendShoot()
		if i < count then
			task.wait(config.FireInterval)
		end
	end
end

local function startAutoFireIfNeeded()
	local config = getWeaponConfig(currentWeapon)
	if config.FireMode ~= "Auto" then return end
	if autoConn then autoConn:Disconnect() end
	autoConn = RunService.Heartbeat:Connect(function()
		if firingHeld then
			sendShoot()
		end
	end)
end

local function stopAutoFire()
	if autoConn then
		autoConn:Disconnect()
		autoConn = nil
	end
end

local function requestReload()
	if not inPlayableState() then return end
	if state.IsReloading then return end
	state.IsReloading = true
	setWeaponState("Reloading")
	reloadEvent:FireServer()
end

local function handlePrimaryFireInputBegan()
	firingHeld = true
	local config = getWeaponConfig(currentWeapon)
	if config.FireMode == "Burst" then
		task.spawn(tryBurstFire)
	else
		sendShoot()
		startAutoFireIfNeeded()
	end
end

local function handlePrimaryFireInputEnded()
	firingHeld = false
	stopAutoFire()
	if not state.IsReloading and not state.IsSwapping then
		if state.IsCrouching then
			setWeaponState("Crouching")
		else
			setWeaponState("Idle")
		end
	end
end

local function updateMovementAndCrosshair(dt)
	local _, humanoid = getCharacterHumanoidRoot()
	if not humanoid then return end
	if humanoid.Health <= 0 then return end

	local targetSpeed = state.IsCrouching and CROUCH_WALK_SPEED or BASE_WALK_SPEED
	humanoid.WalkSpeed = targetSpeed
	humanoid.CameraOffset = state.IsCrouching and Vector3.new(0, CROUCH_CAMERA_OFFSET, 0) or Vector3.zero

	local config = getWeaponConfig(currentWeapon)
	recoil.Spread = math.max(0, recoil.Spread - dt * config.RecoilRecoverySpeed)
	local spread = getLiveSpread(config)
	local targetGap = math.clamp(4 + spread * 2.3, 4, 28)
	state.CrosshairGap = state.CrosshairGap + (targetGap - state.CrosshairGap) * math.clamp(dt * 14, 0, 1)
	updateCrosshair(state.CrosshairGap)
end

combatEvents.AmmoUpdated.OnClientEvent:Connect(function(ammo, reserve)
	currentAmmo = tonumber(ammo) or currentAmmo
	currentReserve = tonumber(reserve) or currentReserve
	if state.IsReloading and currentAmmo >= 0 then
		state.IsReloading = false
		if state.IsCrouching then
			setWeaponState("Crouching")
		else
			setWeaponState("Idle")
		end
	end
	updateHudAmmo()
end)

combatEvents.WeaponUpdated.OnClientEvent:Connect(function(weapon)
	if typeof(weapon) == "string" and weaponData[weapon] then
		currentWeapon = weapon
		if state.IsSwapping then
			state.IsSwapping = false
		end
		if not firingHeld then
			if state.IsCrouching then
				setWeaponState("Crouching")
			else
				setWeaponState("Idle")
			end
		end
		local cfg = getWeaponConfig(currentWeapon)
		if not cfg.Automatic then
			firingHeld = false
			stopAutoFire()
		end
		updateHudAmmo()
	end
end)

combatEvents.HealthUpdated.OnClientEvent:Connect(function(h, maxH)
	updateHudHealth(h, maxH)
end)

local reloadConfirmed = combatEvents:FindFirstChild("ReloadConfirmed")
if reloadConfirmed and reloadConfirmed:IsA("RemoteEvent") then
	reloadConfirmed.OnClientEvent:Connect(function()
		state.IsReloading = true
		setWeaponState("Reloading")
	end)
else
	task.spawn(function()
		local ev = combatEvents:WaitForChild("ReloadConfirmed", 10)
		if ev and ev:IsA("RemoteEvent") then
			ev.OnClientEvent:Connect(function()
				state.IsReloading = true
				setWeaponState("Reloading")
			end)
		end
	end)
end

local equipConfirmed = combatEvents:FindFirstChild("EquipConfirmed")
if equipConfirmed and equipConfirmed:IsA("RemoteEvent") then
	equipConfirmed.OnClientEvent:Connect(function()
		state.IsSwapping = false
		if state.IsCrouching then
			setWeaponState("Crouching")
		else
			setWeaponState("Idle")
		end
	end)
else
	task.spawn(function()
		local ev = combatEvents:WaitForChild("EquipConfirmed", 10)
		if ev and ev:IsA("RemoteEvent") then
			ev.OnClientEvent:Connect(function()
				state.IsSwapping = false
				if state.IsCrouching then
					setWeaponState("Crouching")
				else
					setWeaponState("Idle")
				end
			end)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.One then
		state.IsSwapping = true
		setWeaponState("Swapping")
		equipEvent:FireServer("Primary")
	elseif input.KeyCode == Enum.KeyCode.Two then
		state.IsSwapping = true
		setWeaponState("Swapping")
		equipEvent:FireServer("Secondary")
	elseif input.KeyCode == Enum.KeyCode.Three then
		state.IsSwapping = true
		setWeaponState("Swapping")
		equipEvent:FireServer("Melee")
	elseif input.KeyCode == Enum.KeyCode.Q then
		switchWeapon()
	elseif input.KeyCode == Enum.KeyCode.R then
		requestReload()
	elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
		setCrouchEnabled(not state.IsCrouching)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		handlePrimaryFireInputBegan()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		handlePrimaryFireInputEnded()
	end
end)

clientAction.Event:Connect(function(action)
	if action == "Fire" then
		sendShoot()
	elseif action == "FireDown" then
		handlePrimaryFireInputBegan()
	elseif action == "FireUp" then
		handlePrimaryFireInputEnded()
	elseif action == "Reload" then
		requestReload()
	elseif action == "SwitchWeapon" then
		switchWeapon()
	elseif action == "CrouchToggle" then
		setCrouchEnabled(not state.IsCrouching)
	end
end)

player.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		hum.WalkSpeed = BASE_WALK_SPEED
		hum.CameraOffset = Vector3.zero
		updateHudHealth(hum.Health, hum.MaxHealth)
		hum.HealthChanged:Connect(function(h)
			updateHudHealth(h, hum.MaxHealth)
		end)
	end
	state.IsCrouching = false
	state.IsReloading = false
	state.IsSwapping = false
	state.WeaponState = "Idle"
	pushCombatState(true)
end)

RunService.RenderStepped:Connect(function(dt)
	updateMovementAndCrosshair(dt)
	if not inPlayableState() then
		firingHeld = false
		stopAutoFire()
		if state.IsCrouching then
			state.IsCrouching = false
			setWeaponState("Idle")
		end
	end
end)

updateHudAmmo()
resolveCrosshairParts()
pushCombatState(true)
print("WeaponController local initialized")
