local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FoliageModules = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("FoliageModules"))
local ArchitecturalModules = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("ArchitecturalModules"))
local PropModules = require(ReplicatedStorage:WaitForChild("EnvironmentModules"):WaitForChild("PropModules"))

local DecorativeSets = {}

function DecorativeSets.LaneDecor(parent, cf)
	local m = Instance.new("Model")
	m.Name = "LaneDecor"
	m.Parent = parent
	PropModules.StreetLampPastel(m, cf * CFrame.new(-8, 0, 0))
	PropModules.StreetLampPastel(m, cf * CFrame.new(8, 0, 0))
	FoliageModules.PlanterBoxSet(m, cf * CFrame.new(-8, 0, 4))
	FoliageModules.PlanterBoxSet(m, cf * CFrame.new(8, 0, 4))
	return m
end

function DecorativeSets.CourtyardSet(parent, cf)
	local m = Instance.new("Model")
	m.Name = "CourtyardSet"
	m.Parent = parent
	PropModules.DecorativeStatueBlockBuilt(m, cf)
	ArchitecturalModules.TrimFloorBorder(m, cf, 26, 26)
	FoliageModules.RoseBushDense(m, cf * CFrame.new(11, 0, 0))
	FoliageModules.RoseBushDense(m, cf * CFrame.new(-11, 0, 0))
	return m
end

return DecorativeSets
