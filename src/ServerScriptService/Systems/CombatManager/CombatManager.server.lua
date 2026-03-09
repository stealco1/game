local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local function ensureRemote(folder, name)
	local obj = folder:FindFirstChild(name)
	if obj and obj:IsA("RemoteEvent") then
		return obj
	end
	if obj then obj:Destroy() end
	obj = Instance.new("RemoteEvent")
	obj.Name = name
	obj.Parent = folder
	return obj
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeaponEvents = Remotes:WaitForChild("WeaponEvents")
local ShootEvent = WeaponEvents:WaitForChild("Shoot")
local ReloadEvent = WeaponEvents:WaitForChild("Reload")
local EquipEvent = WeaponEvents:WaitForChild("Equip")
local SetCombatStateEvent = ensureRemote(WeaponEvents, "SetCombatState")

local UIRemotes = Remotes:WaitForChild("UIRemotes")
local SetLoadoutRemote = UIRemotes:WaitForChild("SetLoadout")

local CombatEventsFolder = Remotes:WaitForChild("CombatEvents")
local MatchEventsFolder = Remotes:WaitForChild("MatchEvents")

local AmmoUpdated = CombatEventsFolder:WaitForChild("AmmoUpdated")
local WeaponUpdated = CombatEventsFolder:WaitForChild("WeaponUpdated")
local Hitmarker = CombatEventsFolder:WaitForChild("Hitmarker")
local KillConfirmed = CombatEventsFolder:WaitForChild("KillConfirmed")
local HealthUpdated = CombatEventsFolder:WaitForChild("HealthUpdated")
local ShotConfirmed = ensureRemote(CombatEventsFolder, "ShotConfirmed")
local DryFire = ensureRemote(CombatEventsFolder, "DryFire")
local ReloadConfirmed = ensureRemote(CombatEventsFolder, "ReloadConfirmed")
local EquipConfirmed = ensureRemote(CombatEventsFolder, "EquipConfirmed")
local VFXEvent = ensureRemote(CombatEventsFolder, "VFXEvent")

local KillFeed = MatchEventsFolder:WaitForChild("KillFeed")
local AssistAwarded = ensureRemote(MatchEventsFolder, "AssistAwarded")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local GameState = Shared:WaitForChild("GameState")
local KillSignal = Shared:WaitForChild("KillSignal")
local AssistSignal = Shared:FindFirstChild("AssistSignal")
if not AssistSignal then
	AssistSignal = Instance.new("BindableEvent")
	AssistSignal.Name = "AssistSignal"
	AssistSignal.Parent = Shared
end

local Systems = ServerScriptService:WaitForChild("Systems")
local InventoryManager = require(Systems:WaitForChild("InventoryManager"):WaitForChild("InventoryManager"))
local EconomyManager = require(Systems:WaitForChild("EconomyManager"):WaitForChild("EconomyManager"))

local stateByUserId = {}
local damageLedger = {}

local SWITCH_COOLDOWN = 0.2
local ASSIST_THRESHOLD = 0.30
local POST_SPRINT_FIRE_DELAY = 0.15
local STATE_TIMEOUT = 1.5

local function isInLiveCombatState()
	return GameState.Value == "Playing"
end

local function getWeaponStats(name)
	return WeaponData[name]
end

local function buildWeaponState(weaponName)
	local stats = getWeaponStats(weaponName)
	if not stats then return nil end
	if stats.IsMelee then
		return {
			Ammo = -1,
			Reserve = -1,
			Reloading = false,
			LastFire = 0,
			PatternIndex = 1,
			Bloom = 0,
		}
	end
	return {
		Ammo = stats.MagazineSize,
		Reserve = stats.ReserveAmmo,
		Reloading = false,
		LastFire = 0,
		PatternIndex = 1,
		Bloom = 0,
	}
end

local function getPlayerState(player)
	local state = stateByUserId[player.UserId]
	if state then return state end

	state = {
		CurrentSlot = "Primary",
		CurrentWeapon = "Rifle",
		LastSwitch = 0,
		Weapons = {},
		MovementState = "Idle",
		IsSprinting = false,
		IsCrouching = false,
		LastSprintEnd = 0,
		LastMovementUpdate = 0,
	}
	stateByUserId[player.UserId] = state
	return state
end

local function getLoadout(player)
	local loadout = InventoryManager.GetLoadout(player)
	local primary = loadout.EquippedPrimary
	local secondary = loadout.EquippedSecondary
	local melee = loadout.EquippedMelee
	if not WeaponData[primary] then primary = "Rifle" end
	if not WeaponData[secondary] then secondary = "Pistol" end
	if not WeaponData[melee] then melee = "Knife" end
	return {
		Primary = primary,
		Secondary = secondary,
		Melee = melee,
	}
end

local function ensureLoadoutStates(player)
	local s = getPlayerState(player)
	local loadout = getLoadout(player)
	for _, weaponName in ipairs({loadout.Primary, loadout.Secondary, loadout.Melee}) do
		if not s.Weapons[weaponName] then
			s.Weapons[weaponName] = buildWeaponState(weaponName)
		end
	end
	if s.CurrentSlot ~= "Primary" and s.CurrentSlot ~= "Secondary" and s.CurrentSlot ~= "Melee" then
		s.CurrentSlot = "Primary"
	end
	local desired
	if s.CurrentSlot == "Secondary" then
		desired = loadout.Secondary
	elseif s.CurrentSlot == "Melee" then
		desired = loadout.Melee
	else
		desired = loadout.Primary
	end
	if not WeaponData[desired] then
		desired = loadout.Primary
		s.CurrentSlot = "Primary"
	end
	s.CurrentWeapon = desired
	return s, loadout
end

local function publishWeaponState(player)
	local s = ensureLoadoutStates(player)
	local active = s.Weapons[s.CurrentWeapon]
	local stats = getWeaponStats(s.CurrentWeapon)
	if not active or not stats then return end
	WeaponUpdated:FireClient(player, s.CurrentWeapon)
	EquipConfirmed:FireClient(player, s.CurrentWeapon)
	if stats.IsMelee then
		AmmoUpdated:FireClient(player, -1, -1)
	else
		AmmoUpdated:FireClient(player, active.Ammo, active.Reserve)
	end
end

local function refillLoadoutAmmo(player)
	local s, loadout = ensureLoadoutStates(player)
	for _, weaponName in ipairs({loadout.Primary, loadout.Secondary, loadout.Melee}) do
		local stats = getWeaponStats(weaponName)
		if stats then
			s.Weapons[weaponName] = {
				Ammo = stats.IsMelee and -1 or stats.MagazineSize,
				Reserve = stats.IsMelee and -1 or stats.ReserveAmmo,
				Reloading = false,
				LastFire = 0,
				PatternIndex = 1,
				Bloom = 0,
			}
		end
	end
	s.CurrentSlot = "Primary"
	s.CurrentWeapon = loadout.Primary
end

local function canUseCombat(player)
	if not isInLiveCombatState() then return false end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function applyMovementFlags(s, payload)
	if typeof(payload) ~= "table" then return end
	s.LastMovementUpdate = os.clock()
	s.IsSprinting = false
	s.IsCrouching = payload.Crouching == true
	if typeof(payload.State) == "string" then
		s.MovementState = payload.State
	end
end

local function movementStateExpired(s)
	return os.clock() - (s.LastMovementUpdate or 0) > STATE_TIMEOUT
end

local function canShootFromState(s)
	if movementStateExpired(s) then
		s.MovementState = "Idle"
	end
	return true
end

local function computeServerSpread(player, stats, s)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local base = tonumber(stats.BaseSpread) or tonumber(stats.Spread) or 0
	local moveSpread = tonumber(stats.MoveSpread) or 1.1
	local airSpread = tonumber(stats.AirSpread) or 1.8
	local spread = base
	if humanoid then
		spread += moveSpread * humanoid.MoveDirection.Magnitude
		if humanoid.FloorMaterial == Enum.Material.Air then
			spread += airSpread
		end
	end
	if s and s.IsCrouching then
		spread *= 0.88
	end
	return math.rad(math.max(0, spread))
end

local function isFriendlyFire(attacker, targetHumanoid)
	if not attacker or not targetHumanoid then return false end
	local targetCharacter = targetHumanoid.Parent
	local targetPlayer = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)
	if not targetPlayer or targetPlayer == attacker then
		return false
	end
	local attackerTeam = attacker:GetAttribute("AssignedTeam")
	local targetTeam = targetPlayer:GetAttribute("AssignedTeam")
	return typeof(attackerTeam) == "string" and attackerTeam ~= "" and attackerTeam == targetTeam
end

local function isSpawnProtected(targetHumanoid)
	local targetPlayer = targetHumanoid and Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if not targetPlayer then return false end
	return targetPlayer:GetAttribute("SpawnProtected") == true
end

local function getHitPosition(humanoid, hitPart)
	if hitPart and hitPart:IsA("BasePart") then
		return hitPart.Position
	end
	local model = humanoid and humanoid.Parent
	local hrp = model and model:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.Position
	end
	return Vector3.new()
end

local function applyDistanceFalloff(stats, distance, damage)
	local falloff = stats.RangeFalloff
	if typeof(falloff) ~= "table" then
		return damage
	end
	local startDist = tonumber(falloff.Start) or 0
	local endDist = tonumber(falloff.End) or startDist
	local minScale = tonumber(falloff.MinScale) or 1
	if distance <= startDist then
		return damage
	end
	if endDist <= startDist then
		return damage * minScale
	end
	local alpha = math.clamp((distance - startDist) / (endDist - startDist), 0, 1)
	local scale = 1 + (minScale - 1) * alpha
	return damage * scale
end

local function ledgerHit(victimPlayer, attackerPlayer, dealt, maxHealth)
	if not victimPlayer or not attackerPlayer then return end
	if victimPlayer == attackerPlayer then return end
	local vId = victimPlayer.UserId
	local row = damageLedger[vId]
	if not row then
		row = {MaxHealth = maxHealth or 100, Contributors = {}}
		damageLedger[vId] = row
	end
	row.MaxHealth = math.max(row.MaxHealth or 100, maxHealth or 100)
	row.Contributors[attackerPlayer.UserId] = (row.Contributors[attackerPlayer.UserId] or 0) + dealt
end

local function awardAssists(victimPlayer, killerPlayer)
	if not victimPlayer then return end
	local row = damageLedger[victimPlayer.UserId]
	damageLedger[victimPlayer.UserId] = nil
	if not row then return end
	local thresholdDamage = (row.MaxHealth or 100) * ASSIST_THRESHOLD
	for attackerId, damage in pairs(row.Contributors) do
		if attackerId ~= (killerPlayer and killerPlayer.UserId or -1) and damage >= thresholdDamage then
			local assister = Players:GetPlayerByUserId(attackerId)
			if assister and assister.Parent then
				EconomyManager.AddCoins(assister, 50)
				local current = tonumber(assister:GetAttribute("RoundAssists")) or 0
				assister:SetAttribute("RoundAssists", current + 1)
				AssistAwarded:FireClient(assister, victimPlayer.Name, math.floor(damage + 0.5))
				AssistSignal:Fire(assister, victimPlayer)
			end
		end
	end
end

local function applyDamage(attacker, humanoid, hitPart, stats, rayDistance, weaponName, isMelee, meleeBackstab)
	if not humanoid or humanoid.Health <= 0 then return nil end
	if isFriendlyFire(attacker, humanoid) then return nil end
	if isSpawnProtected(humanoid) then return nil end
	local before = humanoid.Health
	local damage = stats.Damage or 20
	damage = applyDistanceFalloff(stats, rayDistance, damage)
	local headshot = hitPart and hitPart.Name == "Head"
	if headshot then
		damage = damage * (stats.HeadshotMultiplier or 1.5)
	end
	if meleeBackstab == true then
		damage = damage * (stats.BackstabMultiplier or 1)
	end
	humanoid:TakeDamage(damage)
	local afterHealth = humanoid.Health
	local dealt = math.max(0, before - afterHealth)
	if dealt <= 0 then return nil end
	local shownDamage = math.max(1, math.floor(dealt + 0.5))
	local dead = afterHealth <= 0 and before > 0
	local victimPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
	if victimPlayer and victimPlayer ~= attacker then
		ledgerHit(victimPlayer, attacker, dealt, humanoid.MaxHealth)
	end
	if dead then
		KillConfirmed:FireClient(attacker, weaponName or "", headshot, isMelee == true)
		if victimPlayer ~= attacker then
			EconomyManager.AwardKill(attacker)
		end
		KillSignal:Fire(attacker, victimPlayer)
		KillFeed:FireAllClients({
			KillerName = attacker.Name,
			VictimName = victimPlayer and victimPlayer.Name or "Unknown",
			KillerTeam = attacker:GetAttribute("AssignedTeam") or "",
			Weapon = weaponName or "",
			Headshot = headshot,
			IsMelee = isMelee == true,
		})
		if victimPlayer then
			awardAssists(victimPlayer, attacker)
		end
		VFXEvent:FireAllClients("KillBurst", getHitPosition(humanoid, hitPart), {Headshot = headshot})
	end
	if victimPlayer then
		HealthUpdated:FireClient(victimPlayer, afterHealth, humanoid.MaxHealth)
	end
	return {
		Hit = true,
		Damage = shownDamage,
		Headshot = headshot,
		Dead = dead,
		HitPosition = getHitPosition(humanoid, hitPart),
		VictimPlayer = victimPlayer,
	}
end

local function castAndDamage(player, origin, direction, weaponName, s, bloomSpread)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	if (origin - hrp.Position).Magnitude > 20 then return nil end
	if direction.Magnitude < 0.5 then return nil end
	local stats = getWeaponStats(weaponName)
	if not stats then return nil end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}

	local summary = {
		Hit = false,
		Damage = 0,
		Headshot = false,
		HitPosition = nil,
		Weapon = weaponName,
		IsMelee = false,
	}

	local spread = computeServerSpread(player, stats, s) + math.rad(math.max(0, tonumber(bloomSpread) or 0))
	local pellets = math.max(1, math.floor(stats.Pellets or 1))
	for _ = 1, pellets do
		local dir = direction.Unit
		if spread > 0 then
			local rx = (math.random() - 0.5) * spread
			local ry = (math.random() - 0.5) * spread
			dir = (CFrame.fromOrientation(rx, ry, 0):VectorToWorldSpace(dir)).Unit
		end
		local result = Workspace:Raycast(origin, dir * (stats.Range or 500), params)
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if humanoid and model ~= char then
				local distance = (result.Position - origin).Magnitude
				local hitResult = applyDamage(player, humanoid, result.Instance, stats, distance, weaponName, false, false)
				if hitResult and hitResult.Hit then
					summary.Hit = true
					summary.Damage += hitResult.Damage or 0
					summary.Headshot = summary.Headshot or hitResult.Headshot == true
					summary.HitPosition = summary.HitPosition or hitResult.HitPosition
					VFXEvent:FireAllClients(hitResult.Headshot and "HeadshotBurst" or "BulletImpact", hitResult.HitPosition, {
						Weapon = weaponName,
						Headshot = hitResult.Headshot,
					})
				end
			end
		end
	end
	if not summary.Hit then
		return nil
	end
	return summary
end

local function getMeleeTarget(player, origin, direction, stats)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = {player.Character}
	local candidates = Workspace:GetPartBoundsInRadius(origin, stats.Range or 9, overlap)
	local bestHumanoid, bestPart, bestDist, bestBackstab = nil, nil, math.huge, false
	local cone = math.rad(stats.HitCone or 50)
	local minDot = math.cos(cone * 0.5)
	for _, part in ipairs(candidates) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and model ~= player.Character and humanoid.Health > 0 then
			local targetRoot = model:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local toTarget = (targetRoot.Position - origin)
				local dist = toTarget.Magnitude
				if dist > 0.01 then
					local dirToTarget = toTarget.Unit
					if direction:Dot(dirToTarget) >= minDot then
						if dist < bestDist then
							bestDist = dist
							bestHumanoid = humanoid
							bestPart = part
							local targetLook = targetRoot.CFrame.LookVector
							local toAttacker = (origin - targetRoot.Position).Unit
							bestBackstab = targetLook:Dot(toAttacker) < -0.35
						end
					end
				end
			end
		end
	end
	return bestHumanoid, bestPart, bestDist, bestBackstab
end

local function castMeleeDamage(player, direction, weaponName)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local stats = getWeaponStats(weaponName)
	if not stats then return nil end

	local dir = direction
	if dir.Magnitude < 0.01 then
		dir = hrp.CFrame.LookVector
	end
	dir = dir.Unit

	local lunge = math.max(0, tonumber(stats.LungeDistance) or 0)
	if lunge > 0 then
		hrp.CFrame = hrp.CFrame + (dir * math.min(lunge, 3.5))
	end

	local origin = hrp.Position + Vector3.new(0, 1.5, 0)
	local humanoid, hitPart, distance, backstab = getMeleeTarget(player, origin, dir, stats)
	if not humanoid then return nil end
	local hitResult = applyDamage(player, humanoid, hitPart, stats, distance or (stats.Range or 9), weaponName, true, backstab)
	if hitResult and hitResult.Hit then
		VFXEvent:FireAllClients("MeleeTrail", origin, {Weapon = weaponName, Backstab = backstab})
		return {
			Hit = true,
			Damage = hitResult.Damage,
			Headshot = hitResult.Headshot,
			HitPosition = hitResult.HitPosition,
			Weapon = weaponName,
			IsMelee = true,
		}
	end
	return nil
end

ShootEvent.OnServerEvent:Connect(function(player, origin, direction, _clientHitPosition)
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
	if not canUseCombat(player) then return end
	local s = ensureLoadoutStates(player)
	local active = s.Weapons[s.CurrentWeapon]
	local stats = getWeaponStats(s.CurrentWeapon)
	if not active or not stats then return end
	if active.Reloading then return end
	if not canShootFromState(s) then return end

	local now = os.clock()
	local timeSinceLast = now - (active.LastFire or 0)
	local recovery = tonumber(stats.RecoilRecoverySpeed) or 6
	active.Bloom = math.max(0, (active.Bloom or 0) - (timeSinceLast * recovery))
	if timeSinceLast < (stats.FireRate or 0.2) then return end
	active.LastFire = now
	s.MovementState = "Firing"

	if stats.IsMelee then
		local summary = castMeleeDamage(player, direction, s.CurrentWeapon)
		ShotConfirmed:FireClient(player, s.CurrentWeapon)
		if summary and summary.Hit then
			Hitmarker:FireClient(player, summary.Damage, summary.Headshot, summary.HitPosition, summary.Weapon, true)
		end
		return
	end

	if active.Ammo <= 0 then
		DryFire:FireClient(player, s.CurrentWeapon)
		return
	end

	active.Ammo -= 1
	active.Bloom = math.clamp((active.Bloom or 0) + (tonumber(stats.RecoilSpread) or 0.32), 0, 7)
	ShotConfirmed:FireClient(player, s.CurrentWeapon)
	VFXEvent:FireAllClients("MuzzleFlash", origin, {Weapon = s.CurrentWeapon})
	local summary = castAndDamage(player, origin, direction, s.CurrentWeapon, s, active.Bloom)
	if summary and summary.Hit then
		Hitmarker:FireClient(player, summary.Damage, summary.Headshot, summary.HitPosition, summary.Weapon, false)
	end
	AmmoUpdated:FireClient(player, active.Ammo, active.Reserve)
end)

ReloadEvent.OnServerEvent:Connect(function(player)
	if not canUseCombat(player) then return end
	local s = ensureLoadoutStates(player)
	local weaponName = s.CurrentWeapon
	local active = s.Weapons[weaponName]
	local stats = getWeaponStats(weaponName)
	if not active or not stats then return end
	if stats.IsMelee then return end
	if active.Reloading then return end
	if active.Ammo >= stats.MagazineSize then return end
	if active.Reserve <= 0 then return end

	active.Reloading = true
	s.MovementState = "Reloading"
	ReloadConfirmed:FireClient(player, weaponName)
	task.delay(stats.ReloadTime or 1.5, function()
		if not player.Parent then return end
		local state = getPlayerState(player)
		local weaponState = state.Weapons[weaponName]
		local weaponStats = getWeaponStats(weaponName)
		if not weaponState or not weaponStats then return end
		local need = weaponStats.MagazineSize - weaponState.Ammo
		local taken = math.min(need, weaponState.Reserve)
		weaponState.Ammo += taken
		weaponState.Reserve -= taken
		weaponState.Reloading = false
		if state.IsCrouching then
			state.MovementState = "Crouching"
		else
			state.MovementState = "Idle"
		end
		if state.CurrentWeapon == weaponName then
			AmmoUpdated:FireClient(player, weaponState.Ammo, weaponState.Reserve)
		end
	end)
end)

EquipEvent.OnServerEvent:Connect(function(player, request)
	local s, loadout = ensureLoadoutStates(player)
	if typeof(request) ~= "string" then return end

	local now = os.clock()
	if now - s.LastSwitch < SWITCH_COOLDOWN then return end
	s.LastSwitch = now
	s.MovementState = "Swapping"

	if request == "Primary" then
		s.CurrentSlot = "Primary"
		s.CurrentWeapon = loadout.Primary
	elseif request == "Secondary" then
		s.CurrentSlot = "Secondary"
		s.CurrentWeapon = loadout.Secondary
	elseif request == "Melee" then
		s.CurrentSlot = "Melee"
		s.CurrentWeapon = loadout.Melee
	elseif request == "Switch" then
		if s.CurrentSlot == "Primary" then
			s.CurrentSlot = "Secondary"
			s.CurrentWeapon = loadout.Secondary
		elseif s.CurrentSlot == "Secondary" then
			s.CurrentSlot = "Melee"
			s.CurrentWeapon = loadout.Melee
		else
			s.CurrentSlot = "Primary"
			s.CurrentWeapon = loadout.Primary
		end
	elseif request == loadout.Primary then
		s.CurrentSlot = "Primary"
		s.CurrentWeapon = loadout.Primary
	elseif request == loadout.Secondary then
		s.CurrentSlot = "Secondary"
		s.CurrentWeapon = loadout.Secondary
	elseif request == loadout.Melee then
		s.CurrentSlot = "Melee"
		s.CurrentWeapon = loadout.Melee
	else
		return
	end

	publishWeaponState(player)
	if s.IsCrouching then
		s.MovementState = "Crouching"
	else
		s.MovementState = "Idle"
	end
end)

SetLoadoutRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	ensureLoadoutStates(player)
	publishWeaponState(player)
end)
SetCombatStateEvent.OnServerEvent:Connect(function(player, payload)
	if not player or not player.Parent then return end
	local s = ensureLoadoutStates(player)
	applyMovementFlags(s, payload)
end)

local function onCharacterAdded(player, character)
	local s = ensureLoadoutStates(player)
	s.IsSprinting = false
	s.IsCrouching = false
	s.MovementState = "Idle"
	s.LastSprintEnd = 0
	s.LastMovementUpdate = os.clock()
	local hum = character:WaitForChild("Humanoid", 5)
	if hum then
		HealthUpdated:FireClient(player, hum.Health, hum.MaxHealth)
		hum.HealthChanged:Connect(function(h)
			HealthUpdated:FireClient(player, h, hum.MaxHealth)
		end)
		hum.Died:Connect(function()
			damageLedger[player.UserId] = nil
			s.IsSprinting = false
			s.IsCrouching = false
			s.MovementState = "Idle"
		end)
	end
	if isInLiveCombatState() then
		refillLoadoutAmmo(player)
		publishWeaponState(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("RoundAssists", 0)
	ensureLoadoutStates(player)
	publishWeaponState(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	stateByUserId[player.UserId] = nil
	damageLedger[player.UserId] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
	if p:GetAttribute("RoundAssists") == nil then
		p:SetAttribute("RoundAssists", 0)
	end
	ensureLoadoutStates(p)
	publishWeaponState(p)
	p.CharacterAdded:Connect(function(character)
		onCharacterAdded(p, character)
	end)
end

print("CombatManager initialized")
