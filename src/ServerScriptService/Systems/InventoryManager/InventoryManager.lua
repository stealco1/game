local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameState = Shared:WaitForChild("GameState")
local InventoryData = require(Shared:WaitForChild("InventoryData"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))

local UIRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIRemotes")
local LoadoutSync = UIRemotes:WaitForChild("LoadoutSync")
local SetLoadout = UIRemotes:WaitForChild("SetLoadout")

local InventoryManager = {}
local profiles = {}
local initialized = false
local profileChangedCallback = nil

local function copyArray(source)
	local out = {}
	for i, value in ipairs(source or {}) do
		out[i] = value
	end
	return out
end

local function notifyProfileChanged(player)
	if typeof(profileChangedCallback) ~= "function" then return end
	local ok, err = pcall(profileChangedCallback, player)
	if not ok then
		warn("InventoryManager change callback failed", err)
	end
end

local function arrayContains(list, target)
	for _, value in ipairs(list or {}) do
		if value == target then
			return true
		end
	end
	return false
end

local function slotForWeapon(weaponName)
	for slotName, list in pairs(InventoryData.Slots or {}) do
		if arrayContains(list, weaponName) then
			return slotName
		end
	end
	return nil
end

local function buildDefaultProfile()
	return {
		OwnedWeapons = {
			Primary = copyArray(InventoryData.DefaultOwnedWeapons.Primary),
			Secondary = copyArray(InventoryData.DefaultOwnedWeapons.Secondary),
			Melee = copyArray(InventoryData.DefaultOwnedWeapons.Melee),
		},
		EquippedPrimary = InventoryData.DefaultEquipped.Primary,
		EquippedSecondary = InventoryData.DefaultEquipped.Secondary,
		EquippedMelee = InventoryData.DefaultEquipped.Melee,
	}
end

local function sanitizeProfile(profile)
	profile.OwnedWeapons = profile.OwnedWeapons or {}
	profile.OwnedWeapons.Primary = profile.OwnedWeapons.Primary or copyArray(InventoryData.DefaultOwnedWeapons.Primary)
	profile.OwnedWeapons.Secondary = profile.OwnedWeapons.Secondary or copyArray(InventoryData.DefaultOwnedWeapons.Secondary)
	profile.OwnedWeapons.Melee = profile.OwnedWeapons.Melee or copyArray(InventoryData.DefaultOwnedWeapons.Melee)

	if #profile.OwnedWeapons.Primary == 0 then
		profile.OwnedWeapons.Primary = copyArray(InventoryData.DefaultOwnedWeapons.Primary)
	end
	if #profile.OwnedWeapons.Secondary == 0 then
		profile.OwnedWeapons.Secondary = copyArray(InventoryData.DefaultOwnedWeapons.Secondary)
	end
	if #profile.OwnedWeapons.Melee == 0 then
		profile.OwnedWeapons.Melee = copyArray(InventoryData.DefaultOwnedWeapons.Melee)
	end

	if not arrayContains(profile.OwnedWeapons.Primary, profile.EquippedPrimary) or not WeaponData[profile.EquippedPrimary] then
		profile.EquippedPrimary = profile.OwnedWeapons.Primary[1] or InventoryData.DefaultEquipped.Primary
	end
	if not arrayContains(profile.OwnedWeapons.Secondary, profile.EquippedSecondary) or not WeaponData[profile.EquippedSecondary] then
		profile.EquippedSecondary = profile.OwnedWeapons.Secondary[1] or InventoryData.DefaultEquipped.Secondary
	end
	if not arrayContains(profile.OwnedWeapons.Melee, profile.EquippedMelee) then
		profile.EquippedMelee = profile.OwnedWeapons.Melee[1] or InventoryData.DefaultEquipped.Melee
	end
end

local function payloadFor(profile)
	return {
		OwnedWeapons = {
			Primary = copyArray(profile.OwnedWeapons.Primary),
			Secondary = copyArray(profile.OwnedWeapons.Secondary),
			Melee = copyArray(profile.OwnedWeapons.Melee),
		},
		EquippedPrimary = profile.EquippedPrimary,
		EquippedSecondary = profile.EquippedSecondary,
		EquippedMelee = profile.EquippedMelee,
	}
end

function InventoryManager.SetChangeCallback(callback)
	if callback == nil or typeof(callback) == "function" then
		profileChangedCallback = callback
	end
end

function InventoryManager.TrackPlayer(player)
	if profiles[player.UserId] then
		return profiles[player.UserId]
	end
	local profile = buildDefaultProfile()
	sanitizeProfile(profile)
	profiles[player.UserId] = profile
	LoadoutSync:FireClient(player, payloadFor(profile))
	return profile
end

function InventoryManager.RemovePlayer(player)
	profiles[player.UserId] = nil
end

function InventoryManager.GetProfile(player)
	return profiles[player.UserId] or InventoryManager.TrackPlayer(player)
end

function InventoryManager.ApplyPersistedData(player, data)
	local profile = buildDefaultProfile()
	if typeof(data) == "table" then
		if typeof(data.OwnedWeapons) == "table" then
			profile.OwnedWeapons.Primary = copyArray(data.OwnedWeapons.Primary)
			profile.OwnedWeapons.Secondary = copyArray(data.OwnedWeapons.Secondary)
			profile.OwnedWeapons.Melee = copyArray(data.OwnedWeapons.Melee)
		end
		if typeof(data.EquippedPrimary) == "string" then profile.EquippedPrimary = data.EquippedPrimary end
		if typeof(data.EquippedSecondary) == "string" then profile.EquippedSecondary = data.EquippedSecondary end
		if typeof(data.EquippedMelee) == "string" then profile.EquippedMelee = data.EquippedMelee end
	end
	sanitizeProfile(profile)
	profiles[player.UserId] = profile
	LoadoutSync:FireClient(player, payloadFor(profile))
	return profile
end

function InventoryManager.ExportPersistedData(player)
	local profile = InventoryManager.GetProfile(player)
	sanitizeProfile(profile)
	return payloadFor(profile)
end

function InventoryManager.GetLoadout(player)
	local profile = InventoryManager.GetProfile(player)
	return {
		EquippedPrimary = profile.EquippedPrimary,
		EquippedSecondary = profile.EquippedSecondary,
		EquippedMelee = profile.EquippedMelee,
	}
end

function InventoryManager.SyncPlayer(player)
	local profile = InventoryManager.GetProfile(player)
	LoadoutSync:FireClient(player, payloadFor(profile))
end

function InventoryManager.OwnsWeapon(player, weaponName)
	local profile = InventoryManager.GetProfile(player)
	local slot = slotForWeapon(weaponName)
	if not slot then return false end
	return arrayContains(profile.OwnedWeapons[slot], weaponName)
end

function InventoryManager.AddOwnedWeapon(player, weaponName, slot)
	local profile = InventoryManager.GetProfile(player)
	slot = slot or slotForWeapon(weaponName)
	if not slot or not profile.OwnedWeapons[slot] then return false end
	if arrayContains(profile.OwnedWeapons[slot], weaponName) then
		return false
	end
	table.insert(profile.OwnedWeapons[slot], weaponName)
	sanitizeProfile(profile)
	LoadoutSync:FireClient(player, payloadFor(profile))
	notifyProfileChanged(player)
	return true
end

function InventoryManager.SetEquipped(player, slot, weaponName)
	if GameState.Value == "Playing" then
		return false
	end
	local profile = InventoryManager.GetProfile(player)
	if slot == "Primary" then
		if not arrayContains(profile.OwnedWeapons.Primary, weaponName) or not WeaponData[weaponName] then return false end
		profile.EquippedPrimary = weaponName
	elseif slot == "Secondary" then
		if not arrayContains(profile.OwnedWeapons.Secondary, weaponName) or not WeaponData[weaponName] then return false end
		profile.EquippedSecondary = weaponName
	elseif slot == "Melee" then
		if not arrayContains(profile.OwnedWeapons.Melee, weaponName) then return false end
		profile.EquippedMelee = weaponName
	else
		return false
	end
	LoadoutSync:FireClient(player, payloadFor(profile))
	notifyProfileChanged(player)
	return true
end

function InventoryManager.Init()
	if initialized then return end
	initialized = true

	SetLoadout.OnServerEvent:Connect(function(player, slot, weaponName)
		if typeof(slot) ~= "string" then return end
		if slot == "RequestSync" then
			InventoryManager.SyncPlayer(player)
			return
		end
		if typeof(weaponName) ~= "string" then return end
		InventoryManager.SetEquipped(player, slot, weaponName)
	end)
end

InventoryManager.Init()

return InventoryManager
