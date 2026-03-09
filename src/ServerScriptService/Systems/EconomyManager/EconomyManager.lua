local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local InventoryData = require(Shared:WaitForChild("InventoryData"))
local InventoryManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("InventoryManager"):WaitForChild("InventoryManager"))

local UIRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIRemotes")
local CurrencyUpdated = UIRemotes:WaitForChild("CurrencyUpdated")

local EconomyManager = {}

local DATASTORE_NAME = "PlayerData"
local DATASTORE_SCOPE = "v1"
local SAVE_RETRIES = 2
local LOAD_RETRIES = 2
local SAVE_MIN_INTERVAL = 25
local SAVE_FLUSH_INTERVAL = 8
local BUDGET_WAIT_TIMEOUT = 5

local profiles = {}
local saveQueue = {}
local initialized = false
local persistenceDisabled = false
local persistenceWarned = false
local store = nil

do
	local okStore, result = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if okStore then
		store = result
	elseif RunService:IsStudio() then
		persistenceDisabled = true
		persistenceWarned = true
		warn("EconomyManager persistence disabled; using session data only:", result)
	else
		error(result)
	end
end

local function keyFor(userId)
	return string.format("%s_%d", DATASTORE_SCOPE, userId)
end

local function newProfile()
	return {
		Coins = InventoryData.DefaultCoins or 0,
		Loaded = false,
		Dirty = false,
		LastSaveAt = 0,
		SaveInProgress = false,
	}
end

local function sanitizeCoins(value)
	if typeof(value) ~= "number" then return InventoryData.DefaultCoins or 0 end
	return math.max(0, math.floor(value))
end

local function markPersistenceDisabled(reason)
	if persistenceDisabled then return end
	persistenceDisabled = true
	if not persistenceWarned then
		persistenceWarned = true
		warn("EconomyManager persistence disabled; using session data only:", reason)
	end
end

local function isStudioApiAccessError(err)
	if typeof(err) ~= "string" then return false end
	local lower = string.lower(err)
	return string.find(lower, "studio access to apis is not allowed", 1, true) ~= nil
		or string.find(lower, "cannot store data in studio", 1, true) ~= nil
end

local function waitForBudget(requestType, timeoutSeconds, operationName)
	local deadline = os.clock() + (timeoutSeconds or 3)
	while DataStoreService:GetRequestBudgetForRequestType(requestType) < 1 do
		if os.clock() >= deadline then
			if RunService:IsStudio() then
				markPersistenceDisabled((operationName or "DataStore") .. " budget timeout")
			end
			return false
		end
		task.wait(0.2)
	end
	return true
end

local function exportSaveData(player)
	local profile = profiles[player.UserId]
	if not profile then return nil end
	local inv = InventoryManager.ExportPersistedData(player)
	return {
		Coins = sanitizeCoins(profile.Coins),
		OwnedWeapons = inv.OwnedWeapons,
		EquippedPrimary = inv.EquippedPrimary,
		EquippedSecondary = inv.EquippedSecondary,
		EquippedMelee = inv.EquippedMelee,
	}
end

local function pushCurrency(player)
	local profile = profiles[player.UserId]
	if not profile then return end
	CurrencyUpdated:FireClient(player, sanitizeCoins(profile.Coins))
end

local function tryLoad(userId)
	if persistenceDisabled then return nil end
	local lastErr = nil
	for attempt = 1, LOAD_RETRIES do
		if waitForBudget(Enum.DataStoreRequestType.GetAsync, BUDGET_WAIT_TIMEOUT, "GetAsync") then
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(userId))
			end)
			if ok then
				return result
			end
			lastErr = result
			if isStudioApiAccessError(result) then
				markPersistenceDisabled(result)
				return nil
			end
		else
			lastErr = "GetAsync budget wait timeout"
			if persistenceDisabled then return nil end
		end
		task.wait(0.6 + (attempt * 0.2))
	end
	if not persistenceDisabled then
		warn("EconomyManager load failed for user", userId, lastErr)
	end
	return nil
end

local function trySave(userId, data)
	if persistenceDisabled then return false end
	local lastErr = nil
	for attempt = 1, SAVE_RETRIES do
		if waitForBudget(Enum.DataStoreRequestType.SetIncrementAsync, BUDGET_WAIT_TIMEOUT, "UpdateAsync") then
			local ok, result = pcall(function()
				store:UpdateAsync(keyFor(userId), function()
					return data
				end)
			end)
			if ok then
				return true
			end
			lastErr = result
			if isStudioApiAccessError(result) then
				markPersistenceDisabled(result)
				return false
			end
		else
			lastErr = "Set/Update budget wait timeout"
			if persistenceDisabled then return false end
		end
		task.wait(0.8 + (attempt * 0.25))
	end
	if not persistenceDisabled then
		warn("EconomyManager save failed for user", userId, lastErr)
	end
	return false
end

function EconomyManager.TrackPlayer(player)
	if profiles[player.UserId] then
		InventoryManager.SyncPlayer(player)
		pushCurrency(player)
		return
	end

	local profile = newProfile()
	profiles[player.UserId] = profile

	local loaded = nil
	if not persistenceDisabled then
		loaded = tryLoad(player.UserId)
	end

	if typeof(loaded) == "table" then
		profile.Coins = sanitizeCoins(loaded.Coins)
		InventoryManager.ApplyPersistedData(player, loaded)
	else
		InventoryManager.TrackPlayer(player)
		profile.Coins = InventoryData.DefaultCoins or 0
	end

	profile.Loaded = true
	profile.Dirty = false
	profile.LastSaveAt = os.clock()
	saveQueue[player.UserId] = nil
	pushCurrency(player)
end

function EconomyManager.GetCoins(player)
	local profile = profiles[player.UserId]
	if not profile then
		EconomyManager.TrackPlayer(player)
		profile = profiles[player.UserId]
	end
	return sanitizeCoins(profile.Coins)
end

function EconomyManager.MarkDirty(player)
	if persistenceDisabled then return end
	local profile = profiles[player.UserId]
	if not profile then
		EconomyManager.TrackPlayer(player)
		profile = profiles[player.UserId]
	end
	profile.Dirty = true
	if saveQueue[player.UserId] == nil then
		saveQueue[player.UserId] = true
	end
end

function EconomyManager.QueueSave(player, force)
	if persistenceDisabled then return true end
	local profile = profiles[player.UserId]
	if not profile then
		EconomyManager.TrackPlayer(player)
		profile = profiles[player.UserId]
	end
	if force then
		profile.Dirty = true
		saveQueue[player.UserId] = "force"
	else
		if saveQueue[player.UserId] ~= "force" then
			saveQueue[player.UserId] = true
		end
	end
	return true
end

function EconomyManager.SetCoins(player, amount)
	local profile = profiles[player.UserId]
	if not profile then
		EconomyManager.TrackPlayer(player)
		profile = profiles[player.UserId]
	end
	profile.Coins = sanitizeCoins(amount)
	EconomyManager.MarkDirty(player)
	pushCurrency(player)
end

function EconomyManager.AddCoins(player, amount)
	if typeof(amount) ~= "number" then return 0 end
	if amount <= 0 then return EconomyManager.GetCoins(player) end
	local coins = EconomyManager.GetCoins(player)
	EconomyManager.SetCoins(player, coins + amount)
	return EconomyManager.GetCoins(player)
end

function EconomyManager.TrySpendCoins(player, amount)
	if typeof(amount) ~= "number" then return false, EconomyManager.GetCoins(player) end
	amount = math.max(0, math.floor(amount))
	local coins = EconomyManager.GetCoins(player)
	if coins < amount then
		return false, coins
	end
	EconomyManager.SetCoins(player, coins - amount)
	return true, EconomyManager.GetCoins(player)
end

function EconomyManager.AwardKill(killerPlayer)
	if not killerPlayer or not killerPlayer.Parent then return end
	EconomyManager.AddCoins(killerPlayer, 100)
end

function EconomyManager.AwardMatchResults(players, winnerPlayer)
	for _, p in ipairs(players) do
		if p and p.Parent then
			EconomyManager.AddCoins(p, 100)
		end
	end
	if winnerPlayer and winnerPlayer.Parent then
		EconomyManager.AddCoins(winnerPlayer, 500)
	end
end

function EconomyManager.SavePlayerAsync(player, force)
	local profile = profiles[player.UserId]
	if not profile then return true end
	if profile.SaveInProgress then return false end

	if persistenceDisabled then
		profile.Dirty = false
		saveQueue[player.UserId] = nil
		return true
	end

	local shouldForce = force == true or saveQueue[player.UserId] == "force"
	if not shouldForce and not profile.Dirty then
		saveQueue[player.UserId] = nil
		return true
	end

	if not shouldForce and (os.clock() - (profile.LastSaveAt or 0)) < SAVE_MIN_INTERVAL then
		return false
	end

	local data = exportSaveData(player)
	if not data then return false end

	profile.SaveInProgress = true
	local ok = trySave(player.UserId, data)
	profile.SaveInProgress = false

	if ok then
		profile.Dirty = false
		profile.LastSaveAt = os.clock()
		saveQueue[player.UserId] = nil
	else
		saveQueue[player.UserId] = "force"
	end
	return ok
end

function EconomyManager.RemovePlayer(player)
	EconomyManager.QueueSave(player, true)
	EconomyManager.SavePlayerAsync(player, true)
	saveQueue[player.UserId] = nil
	profiles[player.UserId] = nil
	InventoryManager.RemovePlayer(player)
end

local function flushSaveQueueLoop()
	while true do
		task.wait(SAVE_FLUSH_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = profiles[player.UserId]
			if profile and (profile.Dirty or saveQueue[player.UserId] ~= nil) then
				EconomyManager.SavePlayerAsync(player, false)
			end
		end
	end
end

function EconomyManager.Init()
	if initialized then return end
	initialized = true

	InventoryManager.SetChangeCallback(function(player)
		EconomyManager.MarkDirty(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		EconomyManager.TrackPlayer(player)
	end

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			EconomyManager.QueueSave(player, true)
			EconomyManager.SavePlayerAsync(player, true)
		end
	end)

	task.spawn(flushSaveQueueLoop)
end

EconomyManager.Init()

return EconomyManager
