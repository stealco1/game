local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialProfiles = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("MaterialProfiles"))

local ArchitecturalModules = {}

local function part(parent, name, size, cf, profile)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cf
	MaterialProfiles.Apply(p, profile)
	p.Parent = parent
	return p
end

function ArchitecturalModules.PillarTall(parent, cf)
	local m = Instance.new("Model")
	m.Name = "PillarTall"
	m.Parent = parent
	part(m, "Core", Vector3.new(2.8, 18, 2.8), cf * CFrame.new(0, 9, 0), "DecorativeStone")
	part(m, "Cap", Vector3.new(4.2, 1, 4.2), cf * CFrame.new(0, 18.5, 0), "TrimMetal")
	part(m, "Base", Vector3.new(4.6, 1, 4.6), cf * CFrame.new(0, 0.5, 0), "TrimMetal")
	return m
end

function ArchitecturalModules.PillarShort(parent, cf)
	local m = Instance.new("Model")
	m.Name = "PillarShort"
	m.Parent = parent
	part(m, "Core", Vector3.new(3, 10, 3), cf * CFrame.new(0, 5, 0), "DecorativeStone")
	part(m, "Cap", Vector3.new(4.2, 1, 4.2), cf * CFrame.new(0, 10.5, 0), "TrimMetal")
	return m
end

function ArchitecturalModules.ArchwaySingle(parent, cf)
	local m = Instance.new("Model")
	m.Name = "ArchwaySingle"
	m.Parent = parent
	part(m, "Left", Vector3.new(2, 10, 2), cf * CFrame.new(-5, 5, 0), "PastelConcrete")
	part(m, "Right", Vector3.new(2, 10, 2), cf * CFrame.new(5, 5, 0), "PastelConcrete")
	part(m, "Top", Vector3.new(12, 2, 2), cf * CFrame.new(0, 10, 0), "TrimMetal")
	return m
end

function ArchitecturalModules.ArchwayDouble(parent, cf)
	local m = Instance.new("Model")
	m.Name = "ArchwayDouble"
	m.Parent = parent
	ArchitecturalModules.ArchwaySingle(m, cf * CFrame.new(-8, 0, 0))
	ArchitecturalModules.ArchwaySingle(m, cf * CFrame.new(8, 0, 0))
	part(m, "Mid", Vector3.new(2, 12, 2), cf * CFrame.new(0, 6, 0), "TrimMetal")
	return m
end

function ArchitecturalModules.CurvedWallSegment(parent, cf)
	local m = Instance.new("Model")
	m.Name = "CurvedWallSegment"
	m.Parent = parent
	for i = -2, 2 do
		part(m, "Seg" .. i, Vector3.new(6, 8, 2), cf * CFrame.new(i * 5.5, 4, math.abs(i) * 1.2), "PastelConcrete")
	end
	return m
end

function ArchitecturalModules.StaircaseWide(parent, cf)
	local m = Instance.new("Model")
	m.Name = "StaircaseWide"
	m.Parent = parent
	for i = 1, 7 do
		part(m, "Step" .. i, Vector3.new(12, 1, 4), cf * CFrame.new(0, i * 0.5, (i - 1) * -2), "MarbleTile")
	end
	return m
end

function ArchitecturalModules.StaircaseNarrow(parent, cf)
	local m = Instance.new("Model")
	m.Name = "StaircaseNarrow"
	m.Parent = parent
	for i = 1, 7 do
		part(m, "Step" .. i, Vector3.new(6, 1, 3), cf * CFrame.new(0, i * 0.5, (i - 1) * -1.5), "MarbleTile")
	end
	return m
end

function ArchitecturalModules.BalconyRailingSet(parent, cf)
	local m = Instance.new("Model")
	m.Name = "BalconyRailingSet"
	m.Parent = parent
	part(m, "Rail", Vector3.new(24, 1, 1), cf * CFrame.new(0, 3, 0), "TrimMetal")
	for i = -5, 5 do
		part(m, "Post" .. i, Vector3.new(0.5, 3, 0.5), cf * CFrame.new(i * 2, 1.5, 0), "TrimMetal")
	end
	return m
end

function ArchitecturalModules.TrimFloorBorder(parent, cf, width, depth)
	local m = Instance.new("Model")
	m.Name = "TrimFloorBorder"
	m.Parent = parent
	width = width or 40
	depth = depth or 26
	part(m, "N", Vector3.new(width, 0.6, 1), cf * CFrame.new(0, 0.3, -depth / 2), "NeonTrim")
	part(m, "S", Vector3.new(width, 0.6, 1), cf * CFrame.new(0, 0.3, depth / 2), "NeonTrim")
	part(m, "E", Vector3.new(1, 0.6, depth), cf * CFrame.new(width / 2, 0.3, 0), "NeonTrim")
	part(m, "W", Vector3.new(1, 0.6, depth), cf * CFrame.new(-width / 2, 0.3, 0), "NeonTrim")
	return m
end

function ArchitecturalModules.DecorativeWallInset(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DecorativeWallInset"
	m.Parent = parent
	part(m, "Base", Vector3.new(14, 8, 1.2), cf * CFrame.new(0, 4, 0), "PastelConcrete")
	part(m, "Inset", Vector3.new(10, 4, 0.3), cf * CFrame.new(0, 4, -0.45), "ChromePurple")
	return m
end

function ArchitecturalModules.ColumnWithTrim(parent, cf)
	local m = ArchitecturalModules.PillarShort(parent, cf)
	m.Name = "ColumnWithTrim"
	part(m, "Band", Vector3.new(3.4, 0.6, 3.4), cf * CFrame.new(0, 6.5, 0), "NeonTrim")
	return m
end

return ArchitecturalModules
