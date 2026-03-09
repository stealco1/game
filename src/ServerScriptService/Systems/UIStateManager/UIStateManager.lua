local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIStateManager = {}

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchEvents = Remotes:WaitForChild("MatchEvents")
local StateChanged = MatchEvents:WaitForChild("StateChanged")
local IntermissionStart = MatchEvents:WaitForChild("IntermissionStart")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameState = Shared:WaitForChild("GameState")

function UIStateManager.SetState(state)
	GameState.Value = state
	StateChanged:FireAllClients(state)
end

function UIStateManager.SyncPlayer(player)
	StateChanged:FireClient(player, GameState.Value)
end

function UIStateManager.StartIntermission(seconds)
	IntermissionStart:FireAllClients(seconds)
end

function UIStateManager.GetStateValue()
	return GameState
end

return UIStateManager
