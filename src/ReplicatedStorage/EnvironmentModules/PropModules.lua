local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialProfiles = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("MaterialProfiles"))

local PropModules = {}

local function part(parent, name, size, cf, profile, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cf
	p.Shape = shape or Enum.PartType.Block
	MaterialProfiles.Apply(p, profile)
	p.Parent = parent
	return p
end

function PropModules.StreetLampPastel(parent, cf)
	local m = Instance.new("Model")
	m.Name = "StreetLampPastel"
	m.Parent = parent
	part(m, "Pole", Vector3.new(0.8, 12, 0.8), cf * CFrame.new(0, 6, 0), "TrimMetal")
	local lightPart = part(m, "Lamp", Vector3.new(2.5, 1.4, 2.5), cf * CFrame.new(0, 12.7, 0), "NeonTrim")
	local l = Instance.new("PointLight")
	l.Range = 22
	l.Brightness = 1.2
	l.Color = Color3.fromRGB(255, 198, 240)
	l.Parent = lightPart
	return m
end

function PropModules.LanternHanging(parent, cf)
	local m = Instance.new("Model")
	m.Name = "LanternHanging"
	m.Parent = parent
	part(m, "Chain", Vector3.new(0.2, 3, 0.2), cf * CFrame.new(0, -1.5, 0), "TrimMetal")
	local lantern = part(m, "Lantern", Vector3.new(1.8, 1.8, 1.8), cf * CFrame.new(0, -3.3, 0), "NeonTrim")
	local l = Instance.new("PointLight")
	l.Range = 18
	l.Brightness = 1
	l.Color = Color3.fromRGB(240, 190, 255)
	l.Parent = lantern
	return m
end

function PropModules.FountainStatic(parent, cf)
	local m = Instance.new("Model")
	m.Name = "FountainStatic"
	m.Parent = parent
	part(m, "Base", Vector3.new(10, 1.6, 10), cf * CFrame.new(0, 0.8, 0), "DecorativeStone")
	part(m, "Basin", Vector3.new(7, 1, 7), cf * CFrame.new(0, 1.8, 0), "PolishedCeramic")
	part(m, "Core", Vector3.new(2.2, 4, 2.2), cf * CFrame.new(0, 3.8, 0), "TrimMetal")
	return m
end

function PropModules.DecorativeStatueBlockBuilt(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DecorativeStatueBlockBuilt"
	m.Parent = parent
	part(m, "Base", Vector3.new(6, 2, 6), cf * CFrame.new(0, 1, 0), "DecorativeStone")
	part(m, "Body", Vector3.new(3, 7, 3), cf * CFrame.new(0, 5.5, 0), "PolishedCeramic")
	part(m, "Head", Vector3.new(2.4, 2.4, 2.4), cf * CFrame.new(0, 10.2, 0), "PolishedCeramic", Enum.PartType.Ball)
	return m
end

function PropModules.CrystalFloatingCluster(parent, cf)
	local m = Instance.new("Model")
	m.Name = "CrystalFloatingCluster"
	m.Parent = parent
	for i = 1, 5 do
		local p = part(m, "Crystal" .. i, Vector3.new(0.9, 2.5, 0.9), cf * CFrame.new((i - 3) * 1.2, math.sin(i) * 0.5, math.cos(i) * 1.6), "ChromePurple")
		p.CFrame = p.CFrame * CFrame.Angles(math.rad(12 * i), 0, math.rad(16 * i))
		p.CanCollide = false
		p.CanTouch = false
	end
	return m
end

function PropModules.NeonHeartPanel(parent, cf)
	local m = Instance.new("Model")
	m.Name = "NeonHeartPanel"
	m.Parent = parent
	part(m, "Panel", Vector3.new(8, 4, 0.6), cf * CFrame.new(0, 2, 0), "ChromePurple")
	part(m, "Heart", Vector3.new(2.6, 2.4, 0.4), cf * CFrame.new(0, 2, -0.2), "NeonTrim")
	return m
end

function PropModules.DecorativeBench(parent, cf)
	local m = Instance.new("Model")
	m.Name = "DecorativeBench"
	m.Parent = parent
	part(m, "Seat", Vector3.new(8, 0.6, 2), cf * CFrame.new(0, 2.2, 0), "SoftWood")
	part(m, "Back", Vector3.new(8, 2.2, 0.6), cf * CFrame.new(0, 3.5, -0.7), "SoftWood")
	part(m, "Leg1", Vector3.new(0.6, 2, 0.6), cf * CFrame.new(-3.2, 1, 0.5), "TrimMetal")
	part(m, "Leg2", Vector3.new(0.6, 2, 0.6), cf * CFrame.new(3.2, 1, 0.5), "TrimMetal")
	part(m, "Leg3", Vector3.new(0.6, 2, 0.6), cf * CFrame.new(-3.2, 1, -0.5), "TrimMetal")
	part(m, "Leg4", Vector3.new(0.6, 2, 0.6), cf * CFrame.new(3.2, 1, -0.5), "TrimMetal")
	return m
end

function PropModules.BannerRibbonStrand(parent, cf)
	local m = Instance.new("Model")
	m.Name = "BannerRibbonStrand"
	m.Parent = parent
	for i = 1, 8 do
		local p = part(m, "Ribbon" .. i, Vector3.new(1.2, 0.25, 2), cf * CFrame.new((i - 4.5) * 1.4, math.sin(i * 0.5) * 0.5, 0), (i % 2 == 0) and "ChromePink" or "ChromePurple")
		p.CanCollide = false
	end
	return m
end

return PropModules
