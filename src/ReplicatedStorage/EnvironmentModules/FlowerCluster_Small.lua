local Module = {}

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

function Module.Build(parent, originCFrame, options)
	options = options or {}
	local rng = options.Random or Random.new(options.Seed or 333)
	local model = Instance.new("Model")
	model.Name = options.Name or "FlowerCluster_Small"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Flower")
	model:SetAttribute("CoverageFootprint", 9)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local bloomA = options.BloomA or Color3.fromRGB(255, 201, 228)
	local bloomB = options.BloomB or Color3.fromRGB(213, 186, 255)
	local count = rng:NextInteger(5, 8)

	for _ = 1, count do
		local x = rng:NextNumber(-1.5, 1.5)
		local z = rng:NextNumber(-1.5, 1.5)
		local stemH = rng:NextNumber(0.55, 1.15)
		local yOffset = rng:NextNumber(-0.08, 0.12)

		local stem = Instance.new("Part")
		stem.Name = "Stem"
		stem.Size = Vector3.new(0.08, stemH, 0.08)
		stem.Material = Enum.Material.Grass
		stem.Color = Color3.fromRGB(110, 175, 110)
		configurePart(stem)
		stem.CFrame = origin * CFrame.new(x, stemH * 0.5 + yOffset, z)
		stem.Parent = model

		local bloom = Instance.new("Part")
		bloom.Name = "Bloom"
		bloom.Shape = Enum.PartType.Ball
		bloom.Size = Vector3.new(0.32, 0.32, 0.32)
		bloom.Material = Enum.Material.SmoothPlastic
		bloom.Color = (rng:NextNumber() < 0.5) and bloomA or bloomB
		configurePart(bloom)
		bloom.CFrame = origin * CFrame.new(x, stemH + yOffset + 0.14, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
		bloom.Parent = model
	end

	return model
end

return Module