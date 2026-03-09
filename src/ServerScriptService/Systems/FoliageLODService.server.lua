local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CHECK_INTERVAL = 1
local DEFAULT_LOD_DISTANCE = 150

local trackedMap = nil
local trackedClusters = {}

local function isFoliageName(name)
	local n = string.lower(name)
	return string.find(n, "grass", 1, true)
		or string.find(n, "blade", 1, true)
		or string.find(n, "flower", 1, true)
		or string.find(n, "bloom", 1, true)
		or string.find(n, "petal", 1, true)
		or string.find(n, "rose", 1, true)
		or string.find(n, "ivy", 1, true)
		or string.find(n, "vine", 1, true)
end

local function isFoliagePart(part)
	if not part:IsA("BasePart") then
		return false
	end
	if part:GetAttribute("FoliagePart") == true then
		return true
	end
	local parentModel = part:FindFirstAncestorOfClass("Model")
	if parentModel and parentModel:GetAttribute("FoliageCluster") == true then
		return true
	end
	return isFoliageName(part.Name)
end

local function sanitizeFoliagePart(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part:SetAttribute("FoliagePart", true)
	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("SurfaceLight") then
			descendant:Destroy()
		end
	end
end

local function getNearestDistance(position)
	local nearest = math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and hrp then
			local dist = (hrp.Position - position).Magnitude
			if dist < nearest then
				nearest = dist
			end
		end
	end
	return nearest
end

local function setVisualState(cluster, visible)
	for _, descendant in ipairs(cluster:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local base = descendant:GetAttribute("BaseTransparency")
			if base == nil then
				base = descendant.Transparency
				descendant:SetAttribute("BaseTransparency", base)
			end
			descendant.Transparency = visible and base or 1
		elseif descendant:IsA("Decal") then
			local base = descendant:GetAttribute("BaseTransparency")
			if base == nil then
				base = descendant.Transparency
				descendant:SetAttribute("BaseTransparency", base)
			end
			descendant.Transparency = visible and base or 1
		elseif descendant:IsA("SurfaceLight") then
			descendant:Destroy()
		end
	end
end

local function rebuildClusterCache(currentMap)
	table.clear(trackedClusters)
	if not (currentMap and currentMap:IsA("Model")) then
		return
	end
	for _, descendant in ipairs(currentMap:GetDescendants()) do
		if descendant:IsA("BasePart") and isFoliagePart(descendant) then
			sanitizeFoliagePart(descendant)
		end
		if descendant:IsA("Model") and descendant:GetAttribute("FoliageCluster") == true then
			table.insert(trackedClusters, descendant)
		end
	end
end

while task.wait(CHECK_INTERVAL) do
	local currentMap = Workspace:FindFirstChild("CurrentMap")
	if currentMap ~= trackedMap then
		trackedMap = currentMap
		rebuildClusterCache(currentMap)
	end

	for i = #trackedClusters, 1, -1 do
		local cluster = trackedClusters[i]
		if not cluster or not cluster.Parent then
			table.remove(trackedClusters, i)
		else
			local lodDistance = cluster:GetAttribute("LODMaxDistance") or DEFAULT_LOD_DISTANCE
			local pivotPosition = cluster:GetPivot().Position
			local nearest = getNearestDistance(pivotPosition)
			setVisualState(cluster, nearest <= lodDistance)
		end
	end
end
