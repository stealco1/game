local Util = require(script.Parent.Parent:WaitForChild("ModuleUtil"))

local Module = {}
local moduleName = script.Name

local function buildArchwaySingle(parent, origin, options)
	options = options or {}
	local w = options.Width or 14
	local h = options.Height or 14
	local t = options.Thickness or 2
	local d = options.Depth or 4
	local m = Util.NewModel(parent, moduleName)
	Util.AddPart(m, "LeftPillar", Vector3.new(t, h, d), origin * CFrame.new(-w * 0.5 + t * 0.5, h * 0.5, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(228, 220, 236)})
	Util.AddPart(m, "RightPillar", Vector3.new(t, h, d), origin * CFrame.new(w * 0.5 - t * 0.5, h * 0.5, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(228, 220, 236)})
	Util.AddPart(m, "TopBeam", Vector3.new(w, t, d), origin * CFrame.new(0, h - t * 0.5, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(236, 230, 244)})
	return m
end

local function buildPillar(parent, origin, options, tall)
	options = options or {}
	local height = tall and (options.Height or 20) or (options.Height or 10)
	local radius = options.Radius or 1.8
	local m = Util.NewModel(parent, moduleName)
	Util.AddPart(m, "Base", Vector3.new(radius * 2.4, 1.2, radius * 2.4), origin * CFrame.new(0, 0.6, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(225, 216, 234), Shape = Enum.PartType.Cylinder})
	Util.AddPart(m, "Shaft", Vector3.new(height, radius * 2, radius * 2), origin * CFrame.new(0, height * 0.5 + 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), {Material = Enum.Material.Marble, Color = Color3.fromRGB(233, 225, 241), Shape = Enum.PartType.Cylinder})
	Util.AddPart(m, "Cap", Vector3.new(radius * 2.8, 1.4, radius * 2.8), origin * CFrame.new(0, height + 1.9, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(242, 235, 248), Shape = Enum.PartType.Cylinder})
	return m
end

local function buildBalconyRailingSet(parent, origin, options)
	options = options or {}
	local length = options.Length or 20
	local height = options.Height or 4
	local m = Util.NewModel(parent, moduleName)
	local postCount = math.max(2, math.floor(length / 4))
	for i = 0, postCount do
		local x = -length * 0.5 + (length / postCount) * i
		Util.AddPart(m, "Post" .. i, Vector3.new(0.5, height, 0.5), origin * CFrame.new(x, height * 0.5, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(246, 192, 220)})
	end
	Util.AddPart(m, "RailTop", Vector3.new(length, 0.35, 0.35), origin * CFrame.new(0, height - 0.2, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(255, 216, 235)})
	Util.AddPart(m, "RailMid", Vector3.new(length, 0.28, 0.28), origin * CFrame.new(0, height * 0.55, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(240, 210, 240)})
	return m
end

local function buildStaircase(parent, origin, options, wide)
	options = options or {}
	local steps = options.Steps or (wide and 12 or 10)
	local stepWidth = options.Width or (wide and 12 or 7)
	local stepHeight = options.StepHeight or 0.8
	local stepDepth = options.StepDepth or 2
	local m = Util.NewModel(parent, moduleName)
	for i = 1, steps do
		Util.AddPart(m, "Step" .. i, Vector3.new(stepWidth, stepHeight, stepDepth), origin * CFrame.new(0, stepHeight * 0.5 + stepHeight * (i - 1), -stepDepth * 0.5 - stepDepth * (i - 1)), {Material = Enum.Material.Marble, Color = Color3.fromRGB(231, 223, 241)})
	end
	return m
end

local function buildCurvedWallSegment(parent, origin, options)
	options = options or {}
	local radius = options.Radius or 120
	local angle = options.Angle or 15
	local height = options.Height or 32
	local thickness = options.Thickness or 4
	local arcLen = math.max(8, (math.pi * 2 * radius) * (angle / 360))
	local m = Util.NewModel(parent, moduleName)
	Util.AddPart(m, "Wall", Vector3.new(arcLen, height, thickness), origin * CFrame.new(0, height * 0.5, 0), {Material = Enum.Material.Concrete, Color = Color3.fromRGB(214, 205, 226)})
	return m
end

local function buildDecorativeInset(parent, origin, options)
	options = options or {}
	local w = options.Width or 12
	local h = options.Height or 8
	local d = options.Depth or 1
	local m = Util.NewModel(parent, moduleName)
	Util.AddPart(m, "Frame", Vector3.new(w, h, d), origin * CFrame.new(0, h * 0.5, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(225, 214, 236)})
	Util.AddPart(m, "Inset", Vector3.new(w - 1.5, h - 1.5, d + 0.05), origin * CFrame.new(0, h * 0.5, -0.05), {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(242, 228, 246)})
	return m
end

function Module.Build(parent, origin, options)
	origin = origin or CFrame.new()
	if moduleName == "Archway_Single" then
		return buildArchwaySingle(parent, origin, options)
	elseif moduleName == "Archway_Double" then
		local m = Util.NewModel(parent, moduleName)
		buildArchwaySingle(m, origin * CFrame.new(-9, 0, 0), options)
		buildArchwaySingle(m, origin * CFrame.new(9, 0, 0), options)
		return m
	elseif moduleName == "Pillar_Tall" then
		return buildPillar(parent, origin, options, true)
	elseif moduleName == "Pillar_Short" then
		return buildPillar(parent, origin, options, false)
	elseif moduleName == "Balcony_Railing_Set" then
		return buildBalconyRailingSet(parent, origin, options)
	elseif moduleName == "Staircase_Wide" then
		return buildStaircase(parent, origin, options, true)
	elseif moduleName == "Staircase_Narrow" then
		return buildStaircase(parent, origin, options, false)
	elseif moduleName == "Curved_Wall_Segment" then
		return buildCurvedWallSegment(parent, origin, options)
	elseif moduleName == "Decorative_Wall_Inset" then
		return buildDecorativeInset(parent, origin, options)
	end
	return Util.NewModel(parent, moduleName)
end

return Module
