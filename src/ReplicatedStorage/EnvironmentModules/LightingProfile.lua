local Lighting = game:GetService("Lighting")

local LightingProfile = {}

local keep = {
	Sky = true,
}

local function safeSet(obj, propertyName, value)
	pcall(function()
		obj[propertyName] = value
	end)
end

function LightingProfile.Apply()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		elseif not keep[child.ClassName] and (child:IsA("SunRaysEffect") or child:IsA("BlurEffect")) then
			child:Destroy()
		end
	end

	safeSet(Lighting, "Technology", Enum.Technology.Future)
	safeSet(Lighting, "Brightness", 2.3)
	safeSet(Lighting, "GlobalShadows", true)
	safeSet(Lighting, "ShadowSoftness", 0.5)
	safeSet(Lighting, "EnvironmentDiffuseScale", 0.4)
	safeSet(Lighting, "EnvironmentSpecularScale", 0.5)
	safeSet(Lighting, "Ambient", Color3.fromRGB(168, 156, 186))
	safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(183, 171, 204))

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "PastelCC"
	cc.TintColor = Color3.fromRGB(255, 244, 252)
	cc.Contrast = 0.05
	cc.Saturation = 0.1
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PastelBloom"
	bloom.Intensity = 0.2
	bloom.Size = 20
	bloom.Threshold = 1
	bloom.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "PastelAtmosphere"
	atmosphere.Color = Color3.fromRGB(225, 202, 241)
	atmosphere.Decay = Color3.fromRGB(196, 176, 220)
	atmosphere.Density = 0.28
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
end

return LightingProfile
