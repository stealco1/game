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
	local rng = options.Random or Random.new(options.Seed or 555)
	local model = Instance.new("Model")
	model.Name = options.Name or "RoseBush_Large"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "RoseBush")
	model:SetAttribute("CoverageFootprint", 25)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local leafCount = options.LeafCount or 60
	local leafA = options.LeafA or Color3.fromRGB(88, 142, 86)
	local leafB = options.LeafB or Color3.fromRGB(102, 162, 98)

	for _ = 1, leafCount do
		local x = rng:NextNumber(-2.5, 2.5)
		local z = rng:NextNumber(-2.5, 2.5)
		local y = rng:NextNumber(0.2, 4)
		local leaf = Instance.new("Part")
		leaf.Name = "Leaf"
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(rng:NextNumber(0.35, 0.9), rng:NextNumber(0.3, 0.8), rng:NextNumber(0.35, 0.9))
		leaf.Material = Enum.Material.Grass
		leaf.Color = (rng:NextNumber() < 0.5) and leafA or leafB
		leaf.Transparency = (rng:NextNumber() < 0.2) and 0.2 or 0
		configurePart(leaf)
		leaf.CFrame = origin * CFrame.new(x, y, z)
		leaf.Parent = model
	end

	local bloomClusters = rng:NextInteger(2, 3)
	for _ = 1, bloomClusters do
		local center = origin * CFrame.new(rng:NextNumber(-1.8, 1.8), rng:NextNumber(1.2, 3.6), rng:NextNumber(-1.8, 1.8))
		for i = 1, rng:NextInteger(4, 7) do
			local petal = Instance.new("Part")
			petal.Name = "RoseBloom"
			petal.Shape = Enum.PartType.Ball
			petal.Size = Vector3.new(0.25, 0.25, 0.25)
			petal.Material = Enum.Material.SmoothPlastic
			petal.Color = (i % 2 == 0) and Color3.fromRGB(255, 174, 210) or Color3.fromRGB(230, 161, 205)
			configurePart(petal)
			petal.CFrame = center * CFrame.new(rng:NextNumber(-0.25, 0.25), rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.25, 0.25))
			petal.Parent = model
		end
	end

	return model
end

return Module