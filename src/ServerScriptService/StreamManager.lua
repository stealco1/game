local Players = game:GetService("Players")

local StreamManager = {}

local LOAD_RADIUS = 300
local UNLOAD_RADIUS = 350
local CHECK_INTERVAL = 0.75

local function isZoneModel(inst)
	return inst and inst:IsA("Model")
end

local function zoneAlwaysLoaded(zone)
	if zone:GetAttribute("AlwaysLoaded") == true then
		return true
	end
	local n = string.lower(zone.Name)
	if string.find(n, "center", 1, true) or string.find(n, "central", 1, true) then
		return true
	end
	return false
end

local function getZoneDistanceToPlayers(zone)
	local pivot = zone:GetPivot().Position
	local nearest = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - pivot).Magnitude
			if d < nearest then
				nearest = d
			end
		end
	end
	return nearest
end

local function ensureZoneLoaded(handle, zone)
	if handle.ActiveZones[zone] then
		return
	end
	zone.Parent = handle.StreamZones
	handle.ActiveZones[zone] = true
	print("[Streaming] Zone Loaded: " .. zone.Name)
end

local function ensureZoneUnloaded(handle, zone)
	if not handle.ActiveZones[zone] then
		return
	end
	zone.Parent = handle.StreamCache
	handle.ActiveZones[zone] = false
	print("[Streaming] Zone Unloaded: " .. zone.Name)
end

local function collectZones(streamZones)
	local zones = {}
	for _, child in ipairs(streamZones:GetChildren()) do
		if isZoneModel(child) then
			table.insert(zones, child)
		end
	end
	return zones
end

local function tick(handle)
	if not handle.Running then return end
	if not handle.MapModel.Parent then return end

	local seen = {}
	for _, zone in ipairs(collectZones(handle.StreamZones)) do
		seen[zone] = true
	end
	for _, zone in ipairs(collectZones(handle.StreamCache)) do
		seen[zone] = true
	end

	for zone, _ in pairs(seen) do
		if zoneAlwaysLoaded(zone) then
			ensureZoneLoaded(handle, zone)
		else
			local dist = getZoneDistanceToPlayers(zone)
			if dist <= LOAD_RADIUS then
				ensureZoneLoaded(handle, zone)
			elseif dist >= UNLOAD_RADIUS then
				ensureZoneUnloaded(handle, zone)
			end
		end
	end
end

local function stopHandle(handle)
	if not handle or not handle.Running then return end
	handle.Running = false
	for _, conn in ipairs(handle.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(handle.Connections)

	for _, zone in ipairs(collectZones(handle.StreamCache)) do
		zone.Parent = handle.StreamZones
		handle.ActiveZones[zone] = true
	end

	if handle.StreamCache and handle.StreamCache.Parent then
		handle.StreamCache:Destroy()
	end
	table.clear(handle.ActiveZones)
end

function StreamManager.Start(mapModel)
	if not mapModel or not mapModel:IsA("Model") then
		return nil
	end

	local streamZones = mapModel:FindFirstChild("StreamZones")
	if not streamZones or not streamZones:IsA("Folder") then
		return nil
	end

	local handle = {
		MapModel = mapModel,
		StreamZones = streamZones,
		StreamCache = Instance.new("Folder"),
		ActiveZones = {},
		Connections = {},
		Running = true,
	}
	handle.StreamCache.Name = "_StreamCache"
	handle.StreamCache.Parent = mapModel

	for _, zone in ipairs(collectZones(streamZones)) do
		handle.ActiveZones[zone] = true
	end

	task.spawn(function()
		while handle.Running and mapModel.Parent do
			tick(handle)
			task.wait(CHECK_INTERVAL)
		end
		stopHandle(handle)
	end)

	return handle
end

function StreamManager.Stop(handle)
	stopHandle(handle)
end

return StreamManager
