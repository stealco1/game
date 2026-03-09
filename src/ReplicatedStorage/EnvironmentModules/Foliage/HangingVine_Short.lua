local Util = require(script.Parent.Parent:WaitForChild("ModuleUtil"))

local Module = {}
local moduleName = script.Name

local function blade(parent, cf, h, color)
	return Util.AddFoliagePart(parent, "Blade", Vector3.new(0.14, h, 0.14), cf, {
		Material = Enum.Material.Grass,
		Color = color,
	})
end

local function bloom(parent, cf, size, color)
	return Util.AddFoliagePart(parent, "Bloom", Vector3.new(size, size, size), cf, {
		Material = Enum.Material.SmoothPlastic,
		Color = color,
		Shape = Enum.PartType.Ball,
	})
end

function Module.Build(parent, origin, options)
	options = options or {}
	origin = origin or CFrame.new()
	local rng = options.Random or Random.new(options.Seed or 777)
	local m = Util.NewModel(parent, moduleName)
	m:SetAttribute("FoliageCluster", true)
	m:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)

	if moduleName == "GrassPatch_Small" then
		local base = options.Color or Color3.fromRGB(122, 182, 120)
		for i = 1, rng:NextInteger(10, 15) do
			local h = rng:NextNumber(1, 2.5)
			local c = Util.ColorShift(base, 0.05, rng)
			local cf = origin * CFrame.new(rng:NextNumber(-3, 3), h * 0.5, rng:NextNumber(-3, 3)) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-8, 8)))
			blade(m, cf, h, c)
		end
	elseif moduleName == "GrassPatch_Medium" then
		local baseA = options.ColorA or Color3.fromRGB(118, 176, 112)
		local baseB = options.ColorB or Color3.fromRGB(96, 152, 95)
		for i = 1, rng:NextInteger(25, 40) do
			local h = rng:NextNumber(1, 3)
			local base = (rng:NextNumber() < 0.33) and baseB or baseA
			local c = Util.ColorShift(base, 0.06, rng)
			local cf = origin * CFrame.new(rng:NextNumber(-5, 5), h * 0.5, rng:NextNumber(-5, 5)) * CFrame.Angles(math.rad(rng:NextNumber(-10, 10)), math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-10, 10)))
			blade(m, cf, h, c)
		end
	elseif moduleName == "FlowerCluster_Small" then
		local tones = {Color3.fromRGB(255, 201, 228), Color3.fromRGB(213, 186, 255)}
		for i = 1, rng:NextInteger(5, 8) do
			local x = rng:NextNumber(-1.5, 1.5)
			local z = rng:NextNumber(-1.5, 1.5)
			local stemH = rng:NextNumber(0.55, 1.15)
			Util.AddFoliagePart(m, "Stem", Vector3.new(0.08, stemH, 0.08), origin * CFrame.new(x, stemH * 0.5 + rng:NextNumber(-0.08, 0.12), z), {Material = Enum.Material.Grass, Color = Util.ColorShift(Color3.fromRGB(110, 175, 110), 0.06, rng)})
			bloom(m, origin * CFrame.new(x, stemH + 0.12, z), 0.32, tones[rng:NextInteger(1, #tones)])
		end
	elseif moduleName == "FlowerCluster_Medium" then
		local tones = {Color3.fromRGB(255, 204, 229), Color3.fromRGB(220, 191, 255), Color3.fromRGB(245, 224, 255)}
		for i = 1, rng:NextInteger(12, 18) do
			local x = rng:NextNumber(-3, 3)
			local z = rng:NextNumber(-3, 3)
			local stemH = rng:NextNumber(0.6, 1.35)
			Util.AddFoliagePart(m, "Stem", Vector3.new(0.08, stemH, 0.08), origin * CFrame.new(x, stemH * 0.5 + rng:NextNumber(-0.1, 0.16), z), {Material = Enum.Material.Grass, Color = Util.ColorShift(Color3.fromRGB(108, 172, 108), 0.06, rng)})
			bloom(m, origin * CFrame.new(x, stemH + 0.14, z), 0.34, tones[rng:NextInteger(1, #tones)])
		end
	elseif moduleName == "RoseBush_Large" then
		for i = 1, 56 do
			local size = rng:NextNumber(0.35, 0.9)
			local color = (rng:NextNumber() < 0.5) and Color3.fromRGB(88, 142, 86) or Color3.fromRGB(102, 162, 98)
			local leaf = Util.AddFoliagePart(m, "Leaf", Vector3.new(size, rng:NextNumber(0.3, 0.8), size), origin * CFrame.new(rng:NextNumber(-2.5, 2.5), rng:NextNumber(0.2, 4), rng:NextNumber(-2.5, 2.5)), {Material = Enum.Material.Grass, Color = Util.ColorShift(color, 0.06, rng), Shape = Enum.PartType.Ball, Transparency = (rng:NextNumber() < 0.2) and 0.2 or 0})
			leaf:SetAttribute("FoliagePart", true)
		end
		for i = 1, rng:NextInteger(8, 14) do
			bloom(m, origin * CFrame.new(rng:NextNumber(-1.8, 1.8), rng:NextNumber(1.1, 3.8), rng:NextNumber(-1.8, 1.8)), 0.26, (i % 2 == 0) and Color3.fromRGB(255, 174, 210) or Color3.fromRGB(230, 161, 205))
		end
	elseif moduleName == "IvyWall_Climb" then
		local width = options.Width or 4
		local height = options.Height or rng:NextNumber(6, 10)
		local columns = math.max(3, math.floor(width / 0.5))
		local rows = math.max(8, math.floor(height / 0.55))
		for ix = 1, columns do
			for iy = 1, rows do
				if rng:NextNumber() < 0.72 then
					local x = -width * 0.5 + (ix - 0.5) * (width / columns) + rng:NextNumber(-0.1, 0.1)
					local y = (iy - 0.5) * (height / rows) + rng:NextNumber(-0.08, 0.08)
					local z = (options.WallOffset or 0.08) + rng:NextNumber(-0.02, 0.02)
					Util.AddFoliagePart(m, "IvyLeaf", Vector3.new(rng:NextNumber(0.22, 0.42), rng:NextNumber(0.06, 0.12), rng:NextNumber(0.22, 0.42)), origin * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-12, 12))), {Material = Enum.Material.Grass, Color = Util.ColorShift(Color3.fromRGB(94, 149, 92), 0.08, rng)})
				end
			end
		end
	elseif moduleName == "HangingVine_Long" or moduleName == "HangingVine_Short" then
		local count = (moduleName == "HangingVine_Long") and 12 or 7
		for i = 1, count do
			local seg = Util.AddFoliagePart(m, "VineSeg", Vector3.new(0.14, 0.9, 0.14), origin * CFrame.new(rng:NextNumber(-0.35, 0.35), -i * 0.75, rng:NextNumber(-0.35, 0.35)), {Material = Enum.Material.Grass, Color = Util.ColorShift(Color3.fromRGB(94, 148, 94), 0.06, rng)})
			seg:SetAttribute("FoliagePart", true)
		end
	elseif moduleName == "PetalScatter_Decal" then
		local textureId = options.TextureId or "rbxasset://textures/face.png"
		for i = 1, options.Count or rng:NextInteger(12, 18) do
			local a = Util.AddFoliagePart(m, "PetalAnchor", Vector3.new(0.9, 0.02, 0.7), origin * CFrame.new(rng:NextNumber(-4, 4), 0.03, rng:NextNumber(-4, 4)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0), {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(245, 195, 223), Transparency = 1})
			local d = Instance.new("Decal")
			d.Name = "PetalDecal"
			d.Face = Enum.NormalId.Top
			d.Texture = textureId
			d.Transparency = 0.3
			d.Color3 = (rng:NextNumber() < 0.5) and Color3.fromRGB(255, 193, 221) or Color3.fromRGB(226, 193, 255)
			d.Parent = a
		end
	end

	return m
end

return Module
