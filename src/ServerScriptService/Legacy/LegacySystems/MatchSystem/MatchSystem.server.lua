local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Teams = game:GetService("Teams")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIRemotes = Remotes:WaitForChild("UIRemotes")
local PlayGameRemote = UIRemotes:WaitForChild("PlayGame")

local MatchEvents = Remotes:WaitForChild("MatchEvents")
local StateChanged = MatchEvents:WaitForChild("StateChanged")
local MatchStartEv = MatchEvents:WaitForChild("MatchStart")
local MatchEndEv = MatchEvents:WaitForChild("MatchEnd")
local ReturnToLobbyEv = MatchEvents:WaitForChild("ReturnToLobby")
local IntermissionEv = MatchEvents:WaitForChild("IntermissionStart")

local CurrentState = "Lobby"
local MatchDuration = 120
local IntermissionDuration = 8
local MatchRunId = 0

local RedTeam = Teams:FindFirstChild("Red")
local BlueTeam = Teams:FindFirstChild("Blue")
local Spawns = Workspace:FindFirstChild("Spawns")

local function safeTeleportCharacter(player, cf)
	if not player.Character then return end
	local character = player.Character
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		character:PivotTo(cf)
	elseif character.PrimaryPart then
		character:SetPrimaryPartCFrame(cf)
	end
end

local function broadcastState(state)
	CurrentState = state
	for _, p in ipairs(Players:GetPlayers()) do
		StateChanged:FireClient(p, state)
	end
end

local function assignTeam(player)
	if not RedTeam or not BlueTeam then return end
	local redCount = #RedTeam:GetPlayers()
	local blueCount = #BlueTeam:GetPlayers()
	player.Team = redCount <= blueCount and RedTeam or BlueTeam
end

local function getMatchSpawnForPlayer(player)
	local team = player.Team
	local spawnFolder = (team == RedTeam and Spawns and Spawns:FindFirstChild("Team1")) or (team == BlueTeam and Spawns and Spawns:FindFirstChild("Team2"))
	if spawnFolder then
		local children = spawnFolder:GetChildren()
		if #children > 0 then
			local sp = children[math.random(1, #children)]
			if sp:IsA("BasePart") then
				return sp.CFrame + Vector3.new(0, 3, 0)
			end
		end
	end
	return CFrame.new(0, 6, 0)
end

local function clearCharacterForMenu(player)
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end
	character:Destroy()
end

local function spawnPlayerInMatch(player)
	player:LoadCharacter()
	player.CharacterAdded:Wait()
	safeTeleportCharacter(player, getMatchSpawnForPlayer(player))
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end

local function returnToLobby()
	MatchRunId += 1
	broadcastState("Lobby")
	ReturnToLobbyEv:FireAllClients()
	for _, p in ipairs(Players:GetPlayers()) do
		assignTeam(p)
		clearCharacterForMenu(p)
	end
end

local function endMatch(expectedRunId)
	if expectedRunId ~= MatchRunId or CurrentState ~= "Match" then return end
	MatchEndEv:FireAllClients()
	broadcastState("Ending")
	task.wait(4)
	returnToLobby()
end

local function beginLiveMatch(expectedRunId)
	if expectedRunId ~= MatchRunId or CurrentState ~= "Intermission" then return end

	broadcastState("Match")
	MatchStartEv:FireAllClients()
	for _, p in ipairs(Players:GetPlayers()) do
		assignTeam(p)
		spawnPlayerInMatch(p)
		PlayGameRemote:FireClient(p)
	end

	task.delay(MatchDuration, function()
		endMatch(expectedRunId)
	end)
end

local function startMatch(triggerPlayer)
	if CurrentState == "Match" or CurrentState == "Intermission" then
		if triggerPlayer then PlayGameRemote:FireClient(triggerPlayer) end
		return
	end

	MatchRunId += 1
	local runId = MatchRunId

	broadcastState("Intermission")
	IntermissionEv:FireAllClients(IntermissionDuration)
	for _, p in ipairs(Players:GetPlayers()) do
		clearCharacterForMenu(p)
	end
	task.delay(IntermissionDuration, function()
		beginLiveMatch(runId)
	end)
end

PlayGameRemote.OnServerEvent:Connect(function(player)
	startMatch(player)
end)

Players.PlayerAdded:Connect(function(player)
	assignTeam(player)
	StateChanged:FireClient(player, CurrentState)
	player.CharacterAdded:Connect(function(char)
		if CurrentState == "Lobby" or CurrentState == "Intermission" then
			task.defer(function()
				if char and char.Parent then
					clearCharacterForMenu(player)
				end
			end)
		end
	end)
	if CurrentState == "Lobby" or CurrentState == "Intermission" then
		task.defer(function()
			clearCharacterForMenu(player)
		end)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	assignTeam(p)
end

Players.CharacterAutoLoads = false
returnToLobby()

print("MatchSystem initialized")
