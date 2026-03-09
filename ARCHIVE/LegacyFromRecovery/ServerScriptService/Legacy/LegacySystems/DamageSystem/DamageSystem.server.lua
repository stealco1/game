local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WeaponEvents = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WeaponEvents")
local HitEvent = WeaponEvents:WaitForChild("Hit")

HitEvent.OnServerEvent:Connect(function(player, target, damage, weaponName)
	if not target or not target:IsA("Model") then return end
	local humanoid = target:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	humanoid:TakeDamage(damage)
end)
