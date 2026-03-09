local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local combatEvents = remotes:WaitForChild("CombatEvents")
local clientAction = shared:WaitForChild("ClientAction")
local gameState = shared:WaitForChild("GameState")
local weaponData = require(shared:WaitForChild("WeaponData"))

local SOUND_IDS = {
	Hit = "rbxasset://sounds/electronicpingshort.wav",
	Headshot = "rbxasset://sounds/electronicpingshort.wav",
	Kill = "rbxasset://sounds/electronicpingshort.wav",
	MeleeKill = "rbxasset://sounds/electronicpingshort.wav",
	MeleeSwing = "rbxasset://sounds/electronicpingshort.wav",
	Heartbeat = "",
}

local function getBoolSetting(attrName, defaultValue)
	local value = player:GetAttribute(attrName)
	if value == nil then
		player:SetAttribute(attrName, defaultValue)
		return defaultValue
	end
	return value == true
end

local function hitmarkersEnabled()
	return getBoolSetting("ShowHitmarkers", true)
end

local function feedbackSoundsEnabled()
	return getBoolSetting("PlayHitSounds", true)
end

local function lowHealthEffectsEnabled()
	return getBoolSetting("LowHealthEffects", true)
end
local hitmarkerDebounce = 0.06
local killSoundDebounce = 0.1
local meleeSwingDebounce = 0.2
local lastHitSoundAt = 0
local lastKillSoundAt = 0
local lastMeleeSwingAt = 0

local currentWeapon = "Rifle"
local killStreak = 0

local shakeUntil = 0
local shakeMagnitude = 0
local lastShakeOffset = Vector3.zero

local crosshairRoot = nil
local crosshairBars = {}

local feedbackGui = playerGui:FindFirstChild("CombatFeedbackUI")
if not feedbackGui then
	feedbackGui = Instance.new("ScreenGui")
	feedbackGui.Name = "CombatFeedbackUI"
	feedbackGui.ResetOnSpawn = false
	feedbackGui.IgnoreGuiInset = true
	feedbackGui.DisplayOrder = 20
	feedbackGui.Parent = playerGui
end

local hitmarkerRoot = feedbackGui:FindFirstChild("HitmarkerRoot")
if not hitmarkerRoot then
	hitmarkerRoot = Instance.new("Frame")
	hitmarkerRoot.Name = "HitmarkerRoot"
	hitmarkerRoot.AnchorPoint = Vector2.new(0.5, 0.5)
	hitmarkerRoot.Position = UDim2.fromScale(0.5, 0.5)
	hitmarkerRoot.Size = UDim2.fromOffset(42, 42)
	hitmarkerRoot.BackgroundTransparency = 1
	hitmarkerRoot.Parent = feedbackGui
end

local lowHealthVignette = feedbackGui:FindFirstChild("LowHealthVignette")
if not lowHealthVignette then
	lowHealthVignette = Instance.new("Frame")
	lowHealthVignette.Name = "LowHealthVignette"
	lowHealthVignette.Size = UDim2.fromScale(1, 1)
	lowHealthVignette.BackgroundColor3 = Color3.fromRGB(255, 176, 205)
	lowHealthVignette.BackgroundTransparency = 1
	lowHealthVignette.BorderSizePixel = 0
	lowHealthVignette.Visible = false
	lowHealthVignette.ZIndex = 2
	lowHealthVignette.Parent = feedbackGui
end

local killPulse = feedbackGui:FindFirstChild("KillPulse")
if not killPulse then
	killPulse = Instance.new("Frame")
	killPulse.Name = "KillPulse"
	killPulse.Size = UDim2.fromScale(1, 1)
	killPulse.BackgroundColor3 = Color3.fromRGB(228, 180, 255)
	killPulse.BackgroundTransparency = 1
	killPulse.BorderSizePixel = 0
	killPulse.ZIndex = 3
	killPulse.Parent = feedbackGui
end

local streakBadge = feedbackGui:FindFirstChild("StreakBadge")
if not streakBadge then
	streakBadge = Instance.new("TextLabel")
	streakBadge.Name = "StreakBadge"
	streakBadge.AnchorPoint = Vector2.new(0.5, 0)
	streakBadge.Position = UDim2.fromScale(0.5, 0.15)
	streakBadge.Size = UDim2.fromScale(0.24, 0.06)
	streakBadge.BackgroundColor3 = Color3.fromRGB(43, 33, 65)
	streakBadge.BackgroundTransparency = 0.2
	streakBadge.TextColor3 = Color3.fromRGB(255, 238, 255)
	streakBadge.TextScaled = true
	streakBadge.Font = Enum.Font.GothamBold
	streakBadge.Visible = false
	streakBadge.ZIndex = 5
	streakBadge.Parent = feedbackGui
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 12)
	badgeCorner.Parent = streakBadge
end

local damageLayer = feedbackGui:FindFirstChild("DamageLayer")
if not damageLayer then
	damageLayer = Instance.new("Frame")
	damageLayer.Name = "DamageLayer"
	damageLayer.Size = UDim2.fromScale(1, 1)
	damageLayer.BackgroundTransparency = 1
	damageLayer.ZIndex = 8
	damageLayer.Parent = feedbackGui
end

local heartbeatSound = feedbackGui:FindFirstChild("HeartbeatSound")
if not heartbeatSound then
	heartbeatSound = Instance.new("Sound")
	heartbeatSound.Name = "HeartbeatSound"
	heartbeatSound.Parent = feedbackGui
end
heartbeatSound.SoundId = SOUND_IDS.Heartbeat
heartbeatSound.Volume = 0.2
heartbeatSound.PlaybackSpeed = 0.8
heartbeatSound.Looped = false

local function createBar(name, size, pos, rot)
	local bar = hitmarkerRoot:FindFirstChild(name)
	if not bar then
		bar = Instance.new("Frame")
		bar.Name = name
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Size = size
		bar.Position = pos
		bar.Rotation = rot
		bar.BackgroundColor3 = Color3.fromRGB(244, 244, 255)
		bar.BorderSizePixel = 0
		bar.BackgroundTransparency = 1
		bar.ZIndex = 10
		bar.Parent = hitmarkerRoot
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = bar
	end
	return bar
end

local bars = {
	createBar("BarTL", UDim2.fromOffset(3, 12), UDim2.fromOffset(14, 14), 45),
	createBar("BarTR", UDim2.fromOffset(3, 12), UDim2.fromOffset(28, 14), -45),
	createBar("BarBL", UDim2.fromOffset(3, 12), UDim2.fromOffset(14, 28), -45),
	createBar("BarBR", UDim2.fromOffset(3, 12), UDim2.fromOffset(28, 28), 45),
}

local function loadCrosshairRefs()
	local hud = playerGui:FindFirstChild("HUD")
	crosshairRoot = hud and hud:FindFirstChild("Crosshair")
	table.clear(crosshairBars)
	if not crosshairRoot then return end
	for _, child in ipairs(crosshairRoot:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(crosshairBars, child)
		end
	end
end

local function applyCrosshairStreakVisuals()
	if not crosshairRoot or #crosshairBars == 0 then
		loadCrosshairRefs()
	end
	if not crosshairRoot then return end

	local color = Color3.fromRGB(246, 236, 255)
	local transparency = 0.08
	if killStreak >= 7 then
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 6.5)
		color = Color3.fromRGB(255, 196, 244):Lerp(Color3.fromRGB(214, 178, 255), pulse)
		transparency = 0.02
	elseif killStreak >= 5 then
		color = Color3.fromRGB(238, 198, 255)
		transparency = 0.03
	end

	for _, part in ipairs(crosshairBars) do
		part.BackgroundColor3 = color
		part.BackgroundTransparency = transparency
	end
end

local function playSound(id, volume, pitch)
	if id == nil or id == "" then return end
	if not feedbackSoundsEnabled() then return end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.PlaybackSpeed = pitch
	sound.RollOffMaxDistance = 40
	sound.Parent = feedbackGui
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(2, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

local function inPlayingState()
	return gameState.Value == "Playing"
end

local function showHitmarker(headshot)
	if not hitmarkersEnabled() then return end
	local color = headshot and Color3.fromRGB(255, 182, 238) or Color3.fromRGB(248, 246, 255)
	local targetSize = headshot and UDim2.fromOffset(4, 15) or UDim2.fromOffset(3, 12)
	for _, bar in ipairs(bars) do
		bar.BackgroundColor3 = color
		bar.BackgroundTransparency = 0.02
		bar.Size = targetSize
		TweenService:Create(bar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(3, 12),
		}):Play()
	end
end

local function showDamageNumber(damage, headshot, worldPos)
	if player:GetAttribute("ShowDamageNumbers") ~= true then return end
	local cam = workspace.CurrentCamera
	if not cam or typeof(worldPos) ~= "Vector3" then return end
	local screenPos, onScreen = cam:WorldToViewportPoint(worldPos)
	if not onScreen then return end

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
	label.Size = UDim2.fromOffset(80, 26)
	label.Text = tostring(math.max(0, math.floor(tonumber(damage) or 0)))
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.65
	label.TextColor3 = headshot and Color3.fromRGB(255, 190, 238) or Color3.fromRGB(242, 236, 255)
	label.ZIndex = 9
	label.Parent = damageLayer

	TweenService:Create(label, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = label.Position - UDim2.fromOffset(0, 24),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(0.34, function()
		if label and label.Parent then
			label:Destroy()
		end
	end)
end

local function pulseKillVignette()
	killPulse.BackgroundTransparency = 0.9
	TweenService:Create(killPulse, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.72}):Play()
	task.delay(0.1, function()
		TweenService:Create(killPulse, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	end)
end

local function shakeCamera(_magnitude, _duration)
	return
end

RunService.RenderStepped:Connect(function()
	if inPlayingState() and killStreak >= 7 then
		applyCrosshairStreakVisuals()
	end
end)

local function updateStreakUI()
	if killStreak >= 3 then
		streakBadge.Visible = true
		if killStreak >= 7 then
			streakBadge.Text = "STREAK " .. tostring(killStreak) .. "!"
			streakBadge.BackgroundColor3 = Color3.fromRGB(186, 134, 240)
		elseif killStreak >= 5 then
			streakBadge.Text = "STREAK " .. tostring(killStreak)
			streakBadge.BackgroundColor3 = Color3.fromRGB(161, 119, 212)
		else
			streakBadge.Text = "STREAK " .. tostring(killStreak)
			streakBadge.BackgroundColor3 = Color3.fromRGB(136, 103, 186)
		end
	else
		streakBadge.Visible = false
	end
	applyCrosshairStreakVisuals()
end

local function setLowHealthActive(active)
	if not lowHealthEffectsEnabled() then
		active = false
	end
	lowHealthVignette.Visible = active
	local targetTransparency = active and 0.86 or 1
	TweenService:Create(lowHealthVignette, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = targetTransparency,
	}):Play()
	if active then
		if heartbeatSound.SoundId ~= "" and not heartbeatSound.IsPlaying then
			heartbeatSound:Play()
		end
	else
		if heartbeatSound.IsPlaying then
			heartbeatSound:Stop()
		end
	end
end

local function showMeleeSwing()
	if not inPlayingState() then return end
	local now = os.clock()
	if now - lastMeleeSwingAt < meleeSwingDebounce then return end
	lastMeleeSwingAt = now
	local cam = workspace.CurrentCamera
	if not cam then return end

	local slash = Instance.new("Part")
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CastShadow = false
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(255, 196, 232)
	slash.Transparency = 0.25
	slash.Size = Vector3.new(0.12, 0.85, 2.1)
	slash.CFrame = CFrame.new(cam.CFrame.Position + cam.CFrame.LookVector * 2.2)
		* CFrame.Angles(math.rad(math.random(-18, 18)), math.rad(math.random(-12, 12)), math.rad(math.random(-50, 50)))
	slash.Parent = workspace

	TweenService:Create(slash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = slash.Size + Vector3.new(0.2, 0.35, 0.2),
	}):Play()
	task.delay(0.2, function()
		if slash and slash.Parent then
			slash:Destroy()
		end
	end)

	playSound(SOUND_IDS.MeleeSwing, 0.35, 1.05)
end

local function showMeleeImpact(worldPos)
	if typeof(worldPos) ~= "Vector3" then return end
	local spark = Instance.new("Part")
	spark.Anchored = true
	spark.CanCollide = false
	spark.CanQuery = false
	spark.Material = Enum.Material.Neon
	spark.Shape = Enum.PartType.Ball
	spark.Color = Color3.fromRGB(255, 186, 227)
	spark.Size = Vector3.new(0.24, 0.24, 0.24)
	spark.Transparency = 0.15
	spark.Position = worldPos
	spark.Parent = workspace

	TweenService:Create(spark, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(1.1, 1.1, 1.1),
		Transparency = 1,
	}):Play()
	task.delay(0.16, function()
		if spark and spark.Parent then
			spark:Destroy()
		end
	end)
	shakeCamera(0.08, 0.08)
end

local function resetStreak()
	killStreak = 0
	updateStreakUI()
end

combatEvents.WeaponUpdated.OnClientEvent:Connect(function(weapon)
	if typeof(weapon) == "string" and weaponData[weapon] then
		currentWeapon = weapon
	end
end)

combatEvents.Hitmarker.OnClientEvent:Connect(function(damage, headshot, hitPosition, weaponName, isMelee)
	if typeof(weaponName) == "string" and weaponData[weaponName] then
		currentWeapon = weaponName
	end
	headshot = headshot == true
	showHitmarker(headshot)
	showDamageNumber(damage, headshot, hitPosition)

	local now = os.clock()
	if now - lastHitSoundAt >= hitmarkerDebounce then
		lastHitSoundAt = now
		if headshot then
			playSound(SOUND_IDS.Headshot, 0.38, 1.2)
			playSound(SOUND_IDS.Hit, 0.18, 1.38)
		else
			playSound(SOUND_IDS.Hit, 0.24, 1)
			playSound(SOUND_IDS.Hit, 0.12, 1.18)
		end
	end

	if isMelee == true then
		showMeleeImpact(hitPosition)
	end
end)

combatEvents.KillConfirmed.OnClientEvent:Connect(function(weaponName, headshot, isMelee)
	local now = os.clock()
	if now - lastKillSoundAt >= killSoundDebounce then
		lastKillSoundAt = now
		if isMelee == true then
			playSound(SOUND_IDS.MeleeKill, 0.45, 0.95)
			playSound(SOUND_IDS.MeleeSwing, 0.2, 1.28)
		else
			playSound(SOUND_IDS.Kill, 0.48, 1.02)
			playSound(SOUND_IDS.Headshot, 0.18, 0.9)
		end
	end
	pulseKillVignette()
	shakeCamera(0.11, 0.11)
	killStreak += 1
	updateStreakUI()
	if typeof(weaponName) == "string" and weaponData[weaponName] then
		currentWeapon = weaponName
	end
	if headshot == true then
		shakeCamera(0.13, 0.12)
	end
end)

combatEvents.HealthUpdated.OnClientEvent:Connect(function(health, maxHealth)
	local h = tonumber(health) or 0
	local mh = math.max(1, tonumber(maxHealth) or 100)
	setLowHealthActive(inPlayingState() and (h / mh) < 0.25 and h > 0)
	if h <= 0 then
		resetStreak()
	end
end)

local function maybePlayMeleeSwingFromInput()
	if not inPlayingState() then return end
	local data = weaponData[currentWeapon]
	if not data or data.IsMelee ~= true then return end
	showMeleeSwing()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
		maybePlayMeleeSwingFromInput()
	end
end)

clientAction.Event:Connect(function(action)
	if action == "Fire" then
		maybePlayMeleeSwingFromInput()
	end
end)

gameState:GetPropertyChangedSignal("Value"):Connect(function()
	if not inPlayingState() then
		setLowHealthActive(false)
		resetStreak()
	end
end)

player.CharacterAdded:Connect(function(character)
	resetStreak()
	loadCrosshairRefs()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function()
			resetStreak()
			setLowHealthActive(false)
		end)
	end
end)

if player:GetAttribute("ShowDamageNumbers") == nil then
	player:SetAttribute("ShowDamageNumbers", false)
end
if player:GetAttribute("ShowHitmarkers") == nil then
	player:SetAttribute("ShowHitmarkers", true)
end
if player:GetAttribute("PlayHitSounds") == nil then
	player:SetAttribute("PlayHitSounds", true)
end
if player:GetAttribute("LowHealthEffects") == nil then
	player:SetAttribute("LowHealthEffects", true)
end

loadCrosshairRefs()
applyCrosshairStreakVisuals()
print("HitmarkerController initialized")
