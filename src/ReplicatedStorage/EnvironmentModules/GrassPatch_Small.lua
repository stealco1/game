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
	local rng = options.Random or Random.new(options.Seed or 111)
	local model = Instance.new("Model")
	model.Name = options.Name or "GrassPatch_Small"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Grass")
	model:SetAttribute("CoverageFootprint", 36)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local baseColor = options.Color or Color3.fromRGB(122, 182, 120)
	local count = rng:NextInteger(10, 15)

	for _ = 1, count do
		local x = rng:NextNumber(-3, 3)
		local z = rng:NextNumber(-3, 3)
		local h = rng:NextNumber(1, 2.5)
		local part = Instance.new("Part")
		part.Name = "Blade"
		part.Size = Vector3.new(0.14, h, 0.14)
		part.Material = Enum.Material.Grass
		part.Color = baseColor
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		configurePart(part)
		local yaw = math.rad(rng:NextNumber(0, 360))
		local tiltX = math.rad(rng:NextNumber(-8, 8))
		local tiltZ = math.rad(rng:NextNumber(-8, 8))
		part.CFrame = origin * CFrame.new(x, h * 0.5, z) * CFrame.Angles(tiltX, yaw, tiltZ)
		part.Parent = model
	end

	return model
end

return Module