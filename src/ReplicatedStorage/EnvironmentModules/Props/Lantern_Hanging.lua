local Util = require(script.Parent.Parent:WaitForChild("ModuleUtil"))

local Module = {}
local moduleName = script.Name

local function addLampLight(part, brightness, range)
	local point = Instance.new("PointLight")
	point.Brightness = brightness
	point.Range = range
	point.Color = Color3.fromRGB(255, 210, 245)
	point.Shadows = false
	point.Parent = part
end

function Module.Build(parent, origin, options)
	options = options or {}
	origin = origin or CFrame.new()
	local m = Util.NewModel(parent, moduleName)

	if moduleName == "MarbleBench" then
		Util.AddPart(m, "Seat", Vector3.new(8, 0.8, 2.4), origin * CFrame.new(0, 1.8, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(231, 224, 240)})
		Util.AddPart(m, "Back", Vector3.new(8, 2, 0.7), origin * CFrame.new(0, 3.1, -0.85), {Material = Enum.Material.Marble, Color = Color3.fromRGB(238, 230, 246)})
		Util.AddPart(m, "LegL", Vector3.new(0.8, 1.8, 2.2), origin * CFrame.new(-3.2, 0.9, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(221, 213, 232)})
		Util.AddPart(m, "LegR", Vector3.new(0.8, 1.8, 2.2), origin * CFrame.new(3.2, 0.9, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(221, 213, 232)})
	elseif moduleName == "Lantern_Wall" then
		Util.AddPart(m, "Bracket", Vector3.new(0.25, 1.2, 1.4), origin * CFrame.new(0, 1.2, -0.6), {Material = Enum.Material.Metal, Color = Color3.fromRGB(205, 184, 214)})
		local bulb = Util.AddPart(m, "Lantern", Vector3.new(0.9, 1.1, 0.9), origin * CFrame.new(0, 0.4, -1.2), {Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 223, 246), Transparency = 0.25})
		addLampLight(bulb, 1.4, 20)
	elseif moduleName == "Lantern_Hanging" then
		Util.AddPart(m, "Chain", Vector3.new(0.18, 2.6, 0.18), origin * CFrame.new(0, -1.3, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 180, 210)})
		local bulb = Util.AddPart(m, "Lantern", Vector3.new(1.1, 1.3, 1.1), origin * CFrame.new(0, -2.4, 0), {Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 216, 241), Transparency = 0.25})
		addLampLight(bulb, 1.6, 26)
	elseif moduleName == "StreetLamp_Pastel" then
		Util.AddPart(m, "Pole", Vector3.new(0.6, 11, 0.6), origin * CFrame.new(0, 5.5, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(213, 194, 222)})
		Util.AddPart(m, "Arm", Vector3.new(2.4, 0.3, 0.3), origin * CFrame.new(1.1, 10.4, 0), {Material = Enum.Material.Metal, Color = Color3.fromRGB(230, 208, 236)})
		local bulb = Util.AddPart(m, "Lamp", Vector3.new(0.9, 0.9, 0.9), origin * CFrame.new(2.2, 9.9, 0), {Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 214, 240), Transparency = 0.25})
		addLampLight(bulb, 1.7, 28)
	elseif moduleName == "Fountain_Ornate" then
		Util.AddPart(m, "Base", Vector3.new(2, 22, 22), origin * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), {Material = Enum.Material.Marble, Color = Color3.fromRGB(223, 213, 235), Shape = Enum.PartType.Cylinder})
		Util.AddPart(m, "Bowl", Vector3.new(1.5, 14, 14), origin * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), {Material = Enum.Material.Marble, Color = Color3.fromRGB(236, 226, 244), Shape = Enum.PartType.Cylinder})
		Util.AddPart(m, "Column", Vector3.new(5, 2.4, 2.4), origin * CFrame.new(0, 5.2, 0) * CFrame.Angles(0, 0, math.rad(90)), {Material = Enum.Material.Marble, Color = Color3.fromRGB(214, 203, 229), Shape = Enum.PartType.Cylinder})
		local water = Util.AddPart(m, "Water", Vector3.new(0.3, 12.5, 12.5), origin * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), {Material = Enum.Material.Neon, Color = Color3.fromRGB(191, 220, 255), Shape = Enum.PartType.Cylinder, Transparency = 0.35})
		water.CanCollide = false
	elseif moduleName == "Statue_RoseQueen" then
		Util.AddPart(m, "Pedestal", Vector3.new(7, 2, 7), origin * CFrame.new(0, 1, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(226, 217, 237)})
		Util.AddPart(m, "Torso", Vector3.new(2.4, 5, 1.8), origin * CFrame.new(0, 4.5, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(238, 229, 246)})
		Util.AddPart(m, "Head", Vector3.new(1.5, 1.5, 1.5), origin * CFrame.new(0, 7.8, 0), {Material = Enum.Material.Marble, Color = Color3.fromRGB(244, 236, 250), Shape = Enum.PartType.Ball})
	elseif moduleName == "CrystalCluster_Floating" then
		for i = 1, 7 do
			local crystal = Util.AddPart(m, "Crystal" .. i, Vector3.new(1.2, 3.6, 1.2), origin * CFrame.new(math.sin(i * 0.9) * 4, math.random(0, 4), math.cos(i * 1.2) * 4) * CFrame.Angles(math.rad(math.random(-18, 18)), math.rad(math.random(0, 360)), math.rad(math.random(-18, 18))), {Material = Enum.Material.Neon, Color = (i % 2 == 0) and Color3.fromRGB(245, 180, 255) or Color3.fromRGB(175, 221, 255), Transparency = 0.15})
			crystal.Shape = Enum.PartType.Wedge
		end
	elseif moduleName == "Banner_Ribbon_Strand" then
		Util.AddPart(m, "Rope", Vector3.new(16, 0.12, 0.12), origin, {Material = Enum.Material.Fabric, Color = Color3.fromRGB(240, 208, 232), CanCollide = false, CanQuery = false})
		for i = 1, 6 do
			Util.AddPart(m, "Ribbon" .. i, Vector3.new(1.8, 1.6, 0.08), origin * CFrame.new(-6 + i * 2.2, -0.9 - (i % 2) * 0.2, 0), {Material = Enum.Material.Fabric, Color = (i % 2 == 0) and Color3.fromRGB(255, 184, 220) or Color3.fromRGB(220, 184, 255), CanCollide = false, CanQuery = false})
		end
	end

	return m
end

return Module
