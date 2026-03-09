local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local StreamManager = require(ServerScriptService:WaitForChild("StreamManager"))

local MapManager = {
	CurrentMap = nil,
	LastMapName = "",
	CurrentMapName = "",
	ActiveStreamManager = nil,
}

local defaultLightingProps = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	GlobalShadows = Lighting.GlobalShadows,
	ShadowSoftness = Lighting.ShadowSoftness,
}

local defaultLightingChildren = {}
for _, child in ipairs(Lighting:GetChildren()) do
	defaultLightingChildren[#defaultLightingChildren + 1] = child:Clone()
end

local function ensureTempEffectsFolder()
	local f = Workspace:FindFirstChild("TemporaryEffects")
	if f and f:IsA("Folder") then return f end
	if f then f:Destroy() end
	f = Instance.new("Folder")
	f.Name = "TemporaryEffects"
	f.Parent = Workspace
	return f
end

local function clearFolder(folder)
	if not folder then return end
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
end

local function mapsFolder()
	local f = ServerStorage:FindFirstChild("Maps")
	if f and f:IsA("Folder") then
		return f
	end
	return nil
end

local function clearLightingChildren()
	for _, child in ipairs(Lighting:GetChildren()) do
		child:Destroy()
	end
end

local function resetLightingToDefault()
	clearLightingChildren()
	for _, clone in ipairs(defaultLightingChildren) do
		clone:Clone().Parent = Lighting
	end
	for prop, value in pairs(defaultLightingProps) do
		pcall(function()
			Lighting[prop] = value
		end)
	end
end

local function stopAmbience()
	local ambient = SoundService:FindFirstChild("MapAmbience")
	if ambient and ambient:IsA("Sound") then
		ambient:Stop()
		ambient:Destroy()
	end
end

local function enforceSingleCurrentMap()
	local found = {}
	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child.Name == "CurrentMap" then
			found[#found + 1] = child
		end
	end
	if #found > 1 then
		for i = 2, #found do
			found[i]:Destroy()
		end
	end
	if #found >= 1 then
		MapManager.CurrentMap = found[1]
	end
end

function MapManager.GetMapNames()
	local names = {}
	local folder = mapsFolder()
	if not folder then
		return names
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(names, child.Name)
		end
	end
	table.sort(names)
	return names
end

function MapManager.GetEligibleMaps()
	local allMaps = MapManager.GetMapNames()
	if #allMaps <= 2 then
		return allMaps
	end
	local eligible = {}
	for _, mapName in ipairs(allMaps) do
		if mapName ~= MapManager.LastMapName then
			table.insert(eligible, mapName)
		end
	end
	if #eligible == 0 then
		return allMaps
	end
	return eligible
end

function MapManager.GetRandomMap()
	local eligible = MapManager.GetEligibleMaps()
	if #eligible == 0 then
		return nil
	end
	return eligible[math.random(1, #eligible)]
end

function MapManager.ApplyMapSettings(mapModel)
	resetLightingToDefault()
	stopAmbience()

	local settingsModule = mapModel and mapModel:FindFirstChild("MapSettings")
	if settingsModule and settingsModule:IsA("ModuleScript") then
		local ok, settings = pcall(require, settingsModule)
		if ok and typeof(settings) == "table" then
			if typeof(settings.Lighting) == "table" then
				for prop, value in pairs(settings.Lighting) do
					pcall(function()
						Lighting[prop] = value
					end)
				end
			end
			local ambience = settings.Ambience
			if typeof(ambience) == "table" and typeof(ambience.SoundId) == "string" and ambience.SoundId ~= "" then
				local soundId = ambience.SoundId
				local lowerId = string.lower(soundId)
				local isBuiltinPlaceholder = string.find(lowerId, "rbxasset://sounds/", 1, true) ~= nil
				if not isBuiltinPlaceholder then
					local sound = Instance.new("Sound")
					sound.Name = "MapAmbience"
					sound.SoundId = soundId
					sound.Looped = ambience.Looped == true
					sound.Volume = tonumber(ambience.Volume) or 0.2
					sound.PlaybackSpeed = tonumber(ambience.PlaybackSpeed) or 1
					sound.Parent = SoundService
					sound:Play()
				else
					warn("[MapManager] Skipping placeholder ambience SoundId:", soundId)
				end
			end
			if typeof(settings.Skybox) == "table" then
				local sky = Instance.new("Sky")
				sky.Name = "MapSky"
				sky.SkyboxBk = settings.Skybox.Bk or ""
				sky.SkyboxDn = settings.Skybox.Dn or ""
				sky.SkyboxFt = settings.Skybox.Ft or ""
				sky.SkyboxLf = settings.Skybox.Lf or ""
				sky.SkyboxRt = settings.Skybox.Rt or ""
				sky.SkyboxUp = settings.Skybox.Up or ""
				sky.Parent = Lighting
			end
		end
	end
end

function MapManager.UnloadCurrentMap()
	if MapManager.ActiveStreamManager then
		StreamManager.Stop(MapManager.ActiveStreamManager)
		MapManager.ActiveStreamManager = nil
	end
	if MapManager.CurrentMap and MapManager.CurrentMap.Parent then
		MapManager.CurrentMap:Destroy()
	end
	local wsCurrent = Workspace:FindFirstChild("CurrentMap")
	if wsCurrent and wsCurrent:IsA("Model") then
		wsCurrent:Destroy()
	end
	MapManager.CurrentMap = nil
	MapManager.CurrentMapName = ""
	stopAmbience()
	clearFolder(ensureTempEffectsFolder())
	resetLightingToDefault()
	print("[MapManager] Unloaded map")
end

function MapManager.LoadMap(mapName)
	MapManager.UnloadCurrentMap()
	local folder = mapsFolder()
	if not folder then
		warn("[MapManager] Missing ServerStorage.Maps")
		return nil
	end

	local source = folder:FindFirstChild(mapName or "")
	if not (source and source:IsA("Model")) then
		local fallback = MapManager.GetRandomMap()
		if fallback then
			source = folder:FindFirstChild(fallback)
			mapName = fallback
		end
	end
	if not (source and source:IsA("Model")) then
		warn("[MapManager] No map available to load")
		return nil
	end

	local clone = source:Clone()
	clone.Name = "CurrentMap"
	clone.Parent = Workspace
	MapManager.CurrentMap = clone
	MapManager.CurrentMapName = source.Name
	MapManager.LastMapName = source.Name
	clone:SetAttribute("MapName", source.Name)

	MapManager.ApplyMapSettings(clone)

	local streamZones = clone:FindFirstChild("StreamZones")
	if streamZones and streamZones:IsA("Folder") and #streamZones:GetChildren() > 0 then
		MapManager.ActiveStreamManager = StreamManager.Start(clone)
	end

	enforceSingleCurrentMap()
	assert(MapManager.CurrentMap ~= nil, "CurrentMap should never be nil after LoadMap")
	print("[MapManager] Loaded: " .. source.Name)
	return clone
end

function MapManager.GetCurrentMap()
	enforceSingleCurrentMap()
	return MapManager.CurrentMap
end

function MapManager.Initialize()
	enforceSingleCurrentMap()
	if MapManager.CurrentMap then
		MapManager.CurrentMap:Destroy()
		MapManager.CurrentMap = nil
	end
	MapManager.CurrentMapName = ""
	resetLightingToDefault()
	ensureTempEffectsFolder()
end

MapManager.Initialize()

return MapManager
