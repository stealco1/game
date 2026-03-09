local Util = require(script.Parent.Parent:WaitForChild("ModuleUtil"))

local Module = {}
local moduleName = script.Name

function Module.Build(parent, origin, options)
	options = options or {}
	origin = origin or CFrame.new()
	local m = Util.NewModel(parent, moduleName)

	if moduleName == "NeonTrim_Ring" then
		local radius = options.Radius or 34
		local y = options.Y or 0.15
		local segments = options.Segments or 40
		local thickness = options.Thickness or 0.6
		for i = 0, segments - 1 do
			local a = (i / segments) * math.pi * 2
			local a2 = ((i + 1) / segments) * math.pi * 2
			local p1 = Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
			local p2 = Vector3.new(math.cos(a2) * radius, y, math.sin(a2) * radius)
			local len = (p2 - p1).Magnitude
			local mid = (p1 + p2) * 0.5
			local cf = CFrame.lookAt(origin.Position + mid, origin.Position + p2)
			Util.AddPart(m, "Trim" .. i, Vector3.new(len, thickness, thickness), cf, {Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 145, 212), CanCollide = false, CanQuery = false})
		end
	elseif moduleName == "Floor_Trim_Line" then
		local length = options.Length or 30
		local width = options.Width or 0.45
		Util.AddPart(m, "Line", Vector3.new(length, 0.18, width), origin, {Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(247, 214, 238), CanCollide = false, CanQuery = false})
	elseif moduleName == "Gold_Accent_Band" then
		local radius = options.Radius or 120
		local y = options.Y or 30
		local segments = options.Segments or 48
		for i = 0, segments - 1 do
			local a = (i / segments) * math.pi * 2
			local p = Vector3.new(math.cos(a) * radius, y, math.sin(a) * radius)
			local cf = CFrame.new(origin.Position + p) * CFrame.Angles(0, -a + math.rad(90), 0)
			Util.AddPart(m, "Band" .. i, Vector3.new(6, 0.55, 0.6), cf, {Material = Enum.Material.Metal, Color = Color3.fromRGB(246, 221, 156), CanCollide = false, CanQuery = false, CastShadow = false})
		end
	end

	return m
end

return Module
