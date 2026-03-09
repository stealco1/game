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
	local rng = options.Random or Random.new(options.Seed or 222)
	local model = Instance.new("Model")
	model.Name = options.Name or "GrassPatch_Medium"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Grass")
	model:SetAttribute("CoverageFootprint", 100)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local toneA = options.ColorA or Color3.fromRGB(118, 176, 112)
	local toneB = options.ColorB or Color3.fromRGB(96, 152, 95)
	local count = rng:NextInteger(25, 40)

	for _ = 1, count do
		local x = rng:NextNumber(-5, 5)
		local z = rng:NextNumber(-5, 5)
		local h = rng:NextNumber(1, 3)
		local part = Instance.new("Part")
		part.Name = "Blade"
		part.Size = Vector3.new(0.14, h, 0.14)
		part.Material = Enum.Material.Grass
		part.Color = (rng:NextNumber() < 0.32) and toneB or toneA
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		configurePart(part)
		local yaw = math.rad(rng:NextNumber(0, 360))
		local tiltX = math.rad(rng:NextNumber(-10, 10))
		local tiltZ = math.rad(rng:NextNumber(-10, 10))
		part.CFrame = origin * CFrame.new(x, h * 0.5, z) * CFrame.Angles(tiltX, yaw, tiltZ)
		part.Parent = model
	end

	return model
end

return Module