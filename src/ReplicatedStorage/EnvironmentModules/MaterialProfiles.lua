local MaterialProfiles = {}

MaterialProfiles.Profiles = {
	MarbleTile = {Color = Color3.fromRGB(241, 234, 247), Material = Enum.Material.Marble},
	PastelConcrete = {Color = Color3.fromRGB(229, 216, 239), Material = Enum.Material.Concrete},
	ChromePink = {Color = Color3.fromRGB(255, 190, 220), Material = Enum.Material.Metal},
	ChromePurple = {Color = Color3.fromRGB(213, 191, 255), Material = Enum.Material.Metal},
	NeonTrim = {Color = Color3.fromRGB(255, 163, 232), Material = Enum.Material.Neon},
	DecorativeStone = {Color = Color3.fromRGB(200, 187, 215), Material = Enum.Material.Slate},
	SoftWood = {Color = Color3.fromRGB(214, 190, 173), Material = Enum.Material.WoodPlanks},
	TrimMetal = {Color = Color3.fromRGB(202, 188, 225), Material = Enum.Material.DiamondPlate},
	RosePetalTint = {Color = Color3.fromRGB(248, 205, 227), Material = Enum.Material.SmoothPlastic},
	PolishedCeramic = {Color = Color3.fromRGB(236, 228, 244), Material = Enum.Material.Glass},
}

function MaterialProfiles.Apply(part, profileName)
	local profile = MaterialProfiles.Profiles[profileName]
	if not profile or not part or not part:IsA("BasePart") then
		return
	end
	part.Color = profile.Color
	part.Material = profile.Material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

return MaterialProfiles
