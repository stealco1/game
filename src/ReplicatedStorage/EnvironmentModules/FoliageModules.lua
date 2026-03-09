local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialProfiles = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("MaterialProfiles"))

local FoliageModules = {}

local function configurePart(part)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("SurfaceLight") then
			descendant:Destroy()
		end
	end
end

local function markCluster(model, foliageType, footprint, lodDistance)
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", foliageType)
	model:SetAttribute("CoverageFootprint", footprint)
	model:SetAttribute("LODMaxDistance", lodDistance or 150)
end

local function part(parent, name, size, cf, profile, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Shape = shape or Enum.PartType.Block
	MaterialProfiles.Apply(p, profile)
	configurePart(p)
	p.Parent = parent
	return p
end

function FoliageModules.HedgeClusterSmall(parent, cf)
	local m = Instance.new("Model")
	m.Name = "HedgeClusterSmall"
	markCluster(m, "Hedge", 18, 170)
	m.Parent = parent
	for i = -1, 1 do
		part(m, "Hedge" .. i, Vector3.new(4, 3, 3), cf * CFrame.new(i * 2.5, 1.5, 0), "RosePetalTint")
	end
	return m
end

function FoliageModules.HedgeClusterLarge(parent, cf)
	local m = Instance.new("Model")
	m.Name = "HedgeClusterLarge"
	markCluster(m, "Hedge", 30, 180)
	m.Parent = parent
	for i = -2, 2 do
		part(m, "Hedge" .. i, Vector3.new(4, 3.6, 3.5), cf * CFrame.new(i * 2.6, 1.8, 0), "RosePetalTint")
	end
	return m
end

function FoliageModules.RoseBushDense(parent, cf)
	local m = Instance.new("Model")
	m.Name = "RoseBushDense"
	markCluster(m, "RoseBush", 25, 160)
	m.Parent = parent
	for i = 1, 7 do
		local x = math.sin(i * 1.1) * 2.6
		local z = math.cos(i * 0.9) * 2.2
		part(m, "Rose" .. i, Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(x, 1 + (i % 2) * 0.3, z), "ChromePink", Enum.PartType.Ball)
	end
	part(m, "Base", Vector3.new(6, 1.2, 6), cf * CFrame.new(0, 0.6, 0), "RosePetalTint")
	return m
end

function FoliageModules.RoseBushTrimmed(parent, cf)
	local m = Instance.new("Model")
	m.Name = "RoseBushTrimmed"
	markCluster(m, "RoseBush", 20, 160)
	m.Parent = parent
	part(m, "Base", Vector3.new(5, 2.2, 5), cf * CFrame.new(0, 1.1, 0), "RosePetalTint")
	for i = 1, 4 do
		part(m, "Rose" .. i, Vector3.new(1, 1, 1), cf * CFrame.new((i - 2.5) * 1.2, 2.1, 0), "ChromePink", Enum.PartType.Ball)
	end
	return m
end

function FoliageModules.HangingVineCluster(parent, cf)
	local m = Instance.new("Model")
	m.Name = "HangingVineCluster"
	markCluster(m, "Vine", 10, 165)
	m.Parent = parent
	for i = -2, 2 do
		for s = 1, 5 do
			part(m, "Vine" .. i .. "_" .. s, Vector3.new(0.18, 1, 0.18), cf * CFrame.new(i * 0.6, -s * 0.8, (s % 2 == 0) and 0.2 or -0.2), "SoftWood")
		end
	end
	return m
end

function FoliageModules.HangingVineStrand(parent, cf)
	local m = Instance.new("Model")
	m.Name = "HangingVineStrand"
	markCluster(m, "Vine", 6, 165)
	m.Parent = parent
	for s = 1, 8 do
		part(m, "Vine" .. s, Vector3.new(0.16, 1, 0.16), cf * CFrame.new(0, -s * 0.75, 0), "SoftWood")
	end
	return m
end

function FoliageModules.DecorativeGrassPatch(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DecorativeGrassPatch"
	markCluster(m, "Grass", 25, 150)
	m.Parent = parent
	for i = 1, 14 do
		local x = (math.random() - 0.5) * 5
		local z = (math.random() - 0.5) * 5
		part(m, "Blade" .. i, Vector3.new(0.2, 1 + math.random(), 0.2), cf * CFrame.new(x, 0.5, z), "RosePetalTint")
	end
	return m
end

function FoliageModules.PlanterBoxSet(parent, cf)
	local m = Instance.new("Model")
	m.Name = "PlanterBoxSet"
	markCluster(m, "Planter", 24, 180)
	m.Parent = parent
	part(m, "Box", Vector3.new(8, 2, 3), cf * CFrame.new(0, 1, 0), "SoftWood")
	FoliageModules.HedgeClusterSmall(m, cf * CFrame.new(0, 2, 0))
	return m
end

return FoliageModules
