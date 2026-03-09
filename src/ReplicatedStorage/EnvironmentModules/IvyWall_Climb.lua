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
	local rng = options.Random or Random.new(options.Seed or 666)
	local model = Instance.new("Model")
	model.Name = options.Name or "IvyWall_Climb"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Ivy")
	model:SetAttribute("CoverageFootprint", 40)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local width = options.Width or 4
	local height = options.Height or rng:NextNumber(6, 10)
	local columns = math.max(3, math.floor(width / 0.5))
	local rows = math.max(8, math.floor(height / 0.55))
	local wallOffset = options.WallOffset or 0.08

	for ix = 1, columns do
		for iz = 1, rows do
			if rng:NextNumber() < 0.72 then
				local leaf = Instance.new("Part")
				leaf.Name = "IvyLeaf"
				leaf.Size = Vector3.new(rng:NextNumber(0.22, 0.42), rng:NextNumber(0.06, 0.12), rng:NextNumber(0.22, 0.42))
				leaf.Material = Enum.Material.Grass
				leaf.Color = (rng:NextNumber() < 0.35) and Color3.fromRGB(82, 135, 82) or Color3.fromRGB(98, 154, 96)
				configurePart(leaf)
				local x = -width * 0.5 + (ix - 0.5) * (width / columns) + rng:NextNumber(-0.1, 0.1)
				local y = (iz - 0.5) * (height / rows) + rng:NextNumber(-0.08, 0.08)
				local z = wallOffset + rng:NextNumber(-0.02, 0.02)
				leaf.CFrame = origin * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), math.rad(rng:NextNumber(-12, 12)))
				leaf.Parent = model
			end
		end
	end

	return model
end

return Module