local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIRemotes")
local OpenShop = UIRemotes:WaitForChild("OpenShop")
local OpenLoadout = UIRemotes:WaitForChild("OpenLoadout")
local CloseShop = UIRemotes:WaitForChild("CloseShop")
local CloseLoadout = UIRemotes:WaitForChild("CloseLoadout")

OpenShop.OnServerEvent:Connect(function(player)
	OpenShop:FireClient(player)
end)

OpenLoadout.OnServerEvent:Connect(function(player)
	OpenLoadout:FireClient(player)
end)

CloseShop.OnServerEvent:Connect(function(player)
	CloseShop:FireClient(player)
end)

CloseLoadout.OnServerEvent:Connect(function(player)
	CloseLoadout:FireClient(player)
end)
