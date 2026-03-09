local PlayerManager = {}

local function setDefaultAttributes(player)
	if player:GetAttribute("IsLoading") == nil then player:SetAttribute("IsLoading", true) end
	if player:GetAttribute("IsInMenu") == nil then player:SetAttribute("IsInMenu", true) end
	if player:GetAttribute("IsInMatch") == nil then player:SetAttribute("IsInMatch", false) end
	if player:GetAttribute("IsAlive") == nil then player:SetAttribute("IsAlive", false) end
	if player:GetAttribute("AssignedTeam") == nil then player:SetAttribute("AssignedTeam", "") end
	if player:GetAttribute("TeamSwitchPending") == nil then player:SetAttribute("TeamSwitchPending", false) end
end

function PlayerManager.TrackPlayer(player)
	setDefaultAttributes(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			player:SetAttribute("IsAlive", humanoid.Health > 0)
			humanoid.Died:Connect(function()
				player:SetAttribute("IsAlive", false)
			end)
		end
	end)
end
function PlayerManager.ApplyState(player, state)
	if state == "Loading" then
		player:SetAttribute("IsLoading", true)
		player:SetAttribute("IsInMenu", true)
		player:SetAttribute("IsInMatch", false)
		player:SetAttribute("IsAlive", false)
		player:SetAttribute("TeamSwitchPending", false)
	elseif state == "Lobby" or state == "TeamSelect" or state == "MapVote" or state == "Countdown" or state == "Starting" then
		player:SetAttribute("IsLoading", false)
		player:SetAttribute("IsInMenu", true)
		player:SetAttribute("IsInMatch", false)
		player:SetAttribute("IsAlive", false)
		player:SetAttribute("TeamSwitchPending", false)
	elseif state == "Playing" then
		player:SetAttribute("IsLoading", false)
		player:SetAttribute("IsInMenu", false)
		player:SetAttribute("IsInMatch", true)
		player:SetAttribute("TeamSwitchPending", false)
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		player:SetAttribute("IsAlive", hum and hum.Health > 0 or false)
	elseif state == "Ending" then
		player:SetAttribute("IsLoading", false)
		player:SetAttribute("IsInMenu", false)
		player:SetAttribute("IsInMatch", false)
		player:SetAttribute("TeamSwitchPending", false)
	end
end

function PlayerManager.ApplyStateAll(players, state)
	for _, player in ipairs(players) do
		PlayerManager.ApplyState(player, state)
	end
end

return PlayerManager
