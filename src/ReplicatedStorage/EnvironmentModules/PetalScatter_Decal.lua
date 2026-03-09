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
	local rng = options.Random or Random.new(options.Seed or 777)
	local model = Instance.new("Model")
	model.Name = options.Name or "PetalScatter_Decal"
	model:SetAttribute("FoliageCluster", true)
	model:SetAttribute("FoliageType", "Petals")
	model:SetAttribute("CoverageFootprint", 16)
	model:SetAttribute("LODMaxDistance", options.LODMaxDistance or 150)
	model.Parent = parent

	local origin = originCFrame or CFrame.new()
	local count = options.Count or rng:NextInteger(10, 18)
	local radius = options.Radius or 4
	local textureId = options.TextureId or "rbxasset://textures/face.png"

	for _ = 1, count do
		local anchor = Instance.new("Part")
		anchor.Name = "PetalDecalAnchor"
		anchor.Size = Vector3.new(0.9, 0.02, 0.7)
		anchor.Material = Enum.Material.SmoothPlastic
		anchor.Color = Color3.fromRGB(245, 195, 223)
		anchor.Transparency = 1
		configurePart(anchor)
		local x = rng:NextNumber(-radius, radius)
		local z = rng:NextNumber(-radius, radius)
		anchor.CFrame = origin * CFrame.new(x, 0.03 + rng:NextNumber(-0.01, 0.01), z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
		anchor.Parent = model

		local decal = Instance.new("Decal")
		decal.Name = "PetalDecal"
		decal.Face = Enum.NormalId.Top
		decal.Texture = textureId
		decal.Color3 = (rng:NextNumber() < 0.5) and Color3.fromRGB(255, 193, 221) or Color3.fromRGB(226, 193, 255)
		decal.Transparency = 0.3
		decal.Parent = anchor
	end

	return model
end

return Module