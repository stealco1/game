local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeaponEvents = Remotes:WaitForChild("WeaponEvents")
local ShootEvent = WeaponEvents:WaitForChild("Shoot")
local Weapons = ReplicatedStorage:WaitForChild("Weapons")
local Configs = Weapons:WaitForChild("Configs")
local UIRemotes = Remotes:WaitForChild("UIRemotes")
local UpdateAmmo = UIRemotes:WaitForChild("UpdateAmmo")
local UpdateWeapon = UIRemotes:WaitForChild("UpdateWeapon")

local playerWeapons = {}
local playerAmmo = {}

local function getWeaponConfig(weaponName)
	local config = Configs:FindFirstChild(weaponName)
	if config then return require(config) end
	return require(Configs:WaitForChild("Pistol"))
end

local function pushWeaponState(player)
	local weaponName = playerWeapons[player.UserId] or "Rifle"
	local config = getWeaponConfig(weaponName)
	local ammo = playerAmmo[player.UserId]
	if not ammo then return end
	UpdateWeapon:FireClient(player, weaponName)
	UpdateAmmo:FireClient(player, ammo.Ammo, config.MaxAmmo, ammo.Reserve)
end

local function initPlayerWeapon(player, weaponName)
	weaponName = weaponName or "Rifle"
	local config = getWeaponConfig(weaponName)
	playerWeapons[player.UserId] = weaponName
	playerAmmo[player.UserId] = {
		Ammo = config.MaxAmmo or config.Ammo,
		Reserve = config.ReserveAmmo or config.MaxReserve or 0,
	}
	pushWeaponState(player)
end

ShootEvent.OnServerEvent:Connect(function(player, origin, direction, weaponName)
	weaponName = weaponName or playerWeapons[player.UserId] or "Rifle"
	if not playerWeapons[player.UserId] then initPlayerWeapon(player, weaponName) end

	local ammo = playerAmmo[player.UserId]
	local config = getWeaponConfig(weaponName)
	if not ammo or ammo.Ammo <= 0 then return end

	ammo.Ammo -= 1

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {player.Character or {}}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction * (config.Range or 500), raycastParams)
	if result then
		local hit = result.Instance
		local model = hit and hit:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid:TakeDamage(config.Damage or 20)
			end
		end
	end

	UpdateAmmo:FireClient(player, ammo.Ammo, config.MaxAmmo, ammo.Reserve)
end)

WeaponEvents:WaitForChild("Reload").OnServerEvent:Connect(function(player, weaponName)
	weaponName = weaponName or playerWeapons[player.UserId] or "Rifle"
	if not playerAmmo[player.UserId] then initPlayerWeapon(player, weaponName) end

	local ammo = playerAmmo[player.UserId]
	local config = getWeaponConfig(weaponName)
	if not ammo then return end
	if ammo.Ammo >= config.MaxAmmo or ammo.Reserve <= 0 then return end

	local need = config.MaxAmmo - ammo.Ammo
	local take = math.min(need, ammo.Reserve)
	ammo.Ammo += take
	ammo.Reserve -= take

	UpdateAmmo:FireClient(player, ammo.Ammo, config.MaxAmmo, ammo.Reserve)
end)

Players.PlayerAdded:Connect(function(player)
	initPlayerWeapon(player, "Rifle")
	player.CharacterAdded:Connect(function()
		task.defer(function()
			initPlayerWeapon(player, playerWeapons[player.UserId] or "Rifle")
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerWeapons[player.UserId] = nil
	playerAmmo[player.UserId] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
	initPlayerWeapon(p, "Rifle")
	p.CharacterAdded:Connect(function()
		task.defer(function()
			initPlayerWeapon(p, playerWeapons[p.UserId] or "Rifle")
		end)
	end)
end

print("WeaponServer initialized")
