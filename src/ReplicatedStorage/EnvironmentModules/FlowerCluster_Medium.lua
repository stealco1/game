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
	local rng = options.Random or Random.new(options.Seed or 444)
	local model = Instance.new("Model")
	model.Name = options.Name or "FlowerCluster_Medium"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Flower")
	model:SetAttribute("CoverageFootprint", 36)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local tones = {
		options.BloomA or Color3.fromRGB(255, 204, 229),
		options.BloomB or Color3.fromRGB(220, 191, 255),
		options.BloomC or Color3.fromRGB(245, 224, 255),
	}
	local count = rng:NextInteger(12, 18)

	for _ = 1, count do
		local x = rng:NextNumber(-3, 3)
		local z = rng:NextNumber(-3, 3)
		local stemH = rng:NextNumber(0.6, 1.35)
		local yOffset = rng:NextNumber(-0.1, 0.16)

		local stem = Instance.new("Part")
		stem.Name = "Stem"
		stem.Size = Vector3.new(0.08, stemH, 0.08)
		stem.Material = Enum.Material.Grass
		stem.Color = Color3.fromRGB(108, 172, 108)
		configurePart(stem)
		stem.CFrame = origin * CFrame.new(x, stemH * 0.5 + yOffset, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
		stem.Parent = model

		local bloom = Instance.new("Part")
		bloom.Name = "Bloom"
		bloom.Shape = Enum.PartType.Ball
		bloom.Size = Vector3.new(0.34, 0.34, 0.34)
		bloom.Material = Enum.Material.SmoothPlastic
		bloom.Color = tones[rng:NextInteger(1, 3)]
		configurePart(bloom)
		bloom.CFrame = origin * CFrame.new(x, stemH + yOffset + 0.15, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-20, 20)))
		bloom.Parent = model
	end

	return model
end

return Module