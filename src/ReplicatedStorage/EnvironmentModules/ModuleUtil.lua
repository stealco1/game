local Util = {}

function Util.ColorShift(color, amount, rng)
	rng = rng or Random.new()
	local h, s, v = color:ToHSV()
	local dv = rng:NextNumber(-amount, amount)
	local ds = rng:NextNumber(-amount * 0.5, amount * 0.5)
	return Color3.fromHSV(h, math.clamp(s + ds, 0, 1), math.clamp(v + dv, 0, 1))
end

function Util.NewModel(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function Util.AddPart(parent, name, size, cf, opts)
	opts = opts or {}
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Material = opts.Material or Enum.Material.SmoothPlastic
	p.Color = opts.Color or Color3.fromRGB(220, 210, 230)
	p.Transparency = opts.Transparency or 0
	p.Shape = opts.Shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.CanCollide == nil then
		p.CanCollide = true
	else
		p.CanCollide = opts.CanCollide
	end
	if opts.CanTouch == nil then
		p.CanTouch = p.CanCollide
	else
		p.CanTouch = opts.CanTouch
	end
	if opts.CanQuery == nil then
		p.CanQuery = true
	else
		p.CanQuery = opts.CanQuery
	end
	if opts.CastShadow == nil then
		p.CastShadow = true
	else
		p.CastShadow = opts.CastShadow
	end
	p.Parent = parent
	return p
end

function Util.AddFoliagePart(parent, name, size, cf, opts)
	opts = opts or {}
	opts.CanCollide = false
	opts.CanTouch = false
	opts.CanQuery = false
	opts.CastShadow = false
	return Util.AddPart(parent, name, size, cf, opts)
end

return Util
