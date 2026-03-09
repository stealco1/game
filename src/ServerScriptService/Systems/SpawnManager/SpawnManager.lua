local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameState = Shared:WaitForChild("GameState")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchEvents = Remotes:WaitForChild("MatchEvents")
local RespawnStart = MatchEvents:WaitForChild("RespawnStart")

local SpawnManager = {}

local TEAM_NAMES = {"Pink", "Purple"}
local RESPAWN_DELAY = 5
local SPAWN_PROTECTION_DURATION = 2.5

local recentSpawnTimes = {}
local deathConnections = {}
local respawnTokens = {}

local function isValidTeamName(teamName)
	return teamName == "Pink" or teamName == "Purple"
end

local function getTeamObject(teamName)
	if not isValidTeamName(teamName) then return nil end
	local team = Teams:FindFirstChild(teamName)
	if team and team:IsA("Team") then
		return team
	end
	return nil
end

local function getSpawnRoots()
	local roots = {}
	local added = {}

	local function addRoot(root)
		if root and root:IsA("Folder") and not added[root] then
			added[root] = true
			table.insert(roots, root)
		end
	end

	local currentMap = Workspace:FindFirstChild("CurrentMap")
	if currentMap and currentMap:IsA("Model") then
		local mapRoot = currentMap:FindFirstChild("SpawnPoints")
		if mapRoot then
			addRoot(mapRoot)
		end
	end

	local activeMapFolder = Workspace:FindFirstChild("ActiveMap")
	if activeMapFolder then
		for _, mapModel in ipairs(activeMapFolder:GetChildren()) do
			local mapRoot = mapModel:FindFirstChild("SpawnPoints")
			if mapRoot then
				addRoot(mapRoot)
			end
		end
	end

	local root = Workspace:FindFirstChild("SpawnPoints")
	if root then
		addRoot(root)
	end

	local map = Workspace:FindFirstChild("Map")
	if map then
		local mapRoot = map:FindFirstChild("SpawnPoints")
		if mapRoot then
			addRoot(mapRoot)
		end
	end

	local map = Workspace:FindFirstChild("Map")
	if map then
		local mapRoot = map:FindFirstChild("SpawnPoints")
		if mapRoot then
			addRoot(mapRoot)
		end
	end

	if #roots == 0 then
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("Folder") and inst.Name == "SpawnPoints" then
				addRoot(inst)
			end
		end
	end

	return roots
end

local function isSpawnPart(inst)
	if inst:IsA("SpawnLocation") then
		return inst.Enabled
	end
	if inst:IsA("BasePart") then
		return string.find(string.lower(inst.Name), "spawn", 1, true) ~= nil
	end
	return false
end

local function collectSpawnParts(container, out)
	for _, inst in ipairs(container:GetDescendants()) do
		if isSpawnPart(inst) then
			table.insert(out, inst)
		end
	end
end

local function collectTeamSpawns(teamName)
	local list = {}
	local roots = getSpawnRoots()

	for _, root in ipairs(roots) do
		local teamFolder = root:FindFirstChild(teamName .. "Spawns")
		if teamFolder then
			collectSpawnParts(teamFolder, list)
		end
	end

	if #list == 0 then
		for _, root in ipairs(roots) do
			for _, inst in ipairs(root:GetDescendants()) do
				if isSpawnPart(inst) then
					local full = string.lower(inst:GetFullName())
					if string.find(full, string.lower(teamName), 1, true) then
						table.insert(list, inst)
					end
				end
			end
		end
	end

	if #list == 0 then
		for _, root in ipairs(roots) do
			collectSpawnParts(root, list)
		end
	end

	if #list == 0 then
		local fallback = Workspace:FindFirstChild("SpawnLocation")
		if fallback and (fallback:IsA("SpawnLocation") or fallback:IsA("BasePart")) then
			table.insert(list, fallback)
		end
	end

	return list
end

local function spawnIsSafe(spawnPart)
	for _, other in ipairs(Players:GetPlayers()) do
		local character = other.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local hum = character and character:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			if (hrp.Position - spawnPart.Position).Magnitude < 8 then
				return false
			end
		end
	end
	return true
end

local function pickSpawn(teamName)
	local spawns = collectTeamSpawns(teamName)
	if #spawns == 0 then
		return nil
	end

	local now = os.clock()
	local best = spawns[1]
	local bestScore = -math.huge
	for _, spawnPart in ipairs(spawns) do
		local age = now - (recentSpawnTimes[spawnPart:GetFullName()] or 0)
		local safety = spawnIsSafe(spawnPart) and 1000 or 0
		local score = safety + age
		if score > bestScore then
			bestScore = score
			best = spawnPart
		end
	end

	recentSpawnTimes[best:GetFullName()] = now
	return best
end

function SpawnManager.GetAssignedTeam(player)
	local assigned = player:GetAttribute("AssignedTeam")
	if isValidTeamName(assigned) then
		return assigned
	end
	if player.Team and isValidTeamName(player.Team.Name) then
		return player.Team.Name
	end
	return nil
end

function SpawnManager.AssignTeam(player, teamName)
	if not isValidTeamName(teamName) then
		teamName = TEAM_NAMES[math.random(1, #TEAM_NAMES)]
	end
	player:SetAttribute("AssignedTeam", teamName)
	local teamObj = getTeamObject(teamName)
	if teamObj then
		player.Team = teamObj
	end
	return teamName
end

local function clearTools(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			child:Destroy()
		end
	end
end

local function disconnectDeath(player)
	local conn = deathConnections[player.UserId]
	if conn then
		conn:Disconnect()
		deathConnections[player.UserId] = nil
	end
end

local function applySpawnProtection(player, character)
	player:SetAttribute("SpawnProtected", true)
	local ff = character:FindFirstChildOfClass("ForceField")
	if not ff then
		ff = Instance.new("ForceField")
		ff.Visible = true
		ff.Parent = character
	end
	task.delay(SPAWN_PROTECTION_DURATION, function()
		if not player.Parent then return end
		if player.Character ~= character then return end
		player:SetAttribute("SpawnProtected", false)
		local cur = character:FindFirstChildOfClass("ForceField")
		if cur then
			cur:Destroy()
		end
	end)
end

function SpawnManager.ClearPlayer(player)
	respawnTokens[player.UserId] = nil
	disconnectDeath(player)
	clearTools(player:FindFirstChild("Backpack"))
	if player.Character then
		clearTools(player.Character)
		player.Character:Destroy()
	end
	player:SetAttribute("SpawnProtected", false)
	player:SetAttribute("IsAlive", false)
end

local function scheduleRespawn(player, seconds)
	if GameState.Value ~= "Playing" then return end
	local token = (respawnTokens[player.UserId] or 0) + 1
	respawnTokens[player.UserId] = token
	RespawnStart:FireClient(player, seconds)
	task.delay(seconds, function()
		if not player.Parent then return end
		if GameState.Value ~= "Playing" then return end
		if respawnTokens[player.UserId] ~= token then return end
		SpawnManager.SpawnPlayer(player)
	end)
end

local function hookCharacterDeath(player, character)
	disconnectDeath(player)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	player:SetAttribute("IsAlive", humanoid.Health > 0)
	deathConnections[player.UserId] = humanoid.Died:Connect(function()
		player:SetAttribute("SpawnProtected", false)
		player:SetAttribute("IsAlive", false)
		scheduleRespawn(player, RESPAWN_DELAY)
	end)
end

local function getFallbackSpawnCFrame()
	local lobby = Workspace:FindFirstChild("LobbySpawn")
	if lobby and (lobby:IsA("SpawnLocation") or lobby:IsA("BasePart")) then
		return lobby.CFrame + Vector3.new(0, 3, 0)
	end
	local fallback = Workspace:FindFirstChild("SpawnLocation")
	if fallback and (fallback:IsA("SpawnLocation") or fallback:IsA("BasePart")) then
		return fallback.CFrame + Vector3.new(0, 3, 0)
	end
	return CFrame.new(0, 8, 0)
end

function SpawnManager.SpawnPlayer(player)
	local teamName = SpawnManager.AssignTeam(player, SpawnManager.GetAssignedTeam(player))
	local spawnPart = pickSpawn(teamName)
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	if character then
		if spawnPart then
			character:PivotTo(spawnPart.CFrame + Vector3.new(0, 3, 0))
		else
			character:PivotTo(getFallbackSpawnCFrame())
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
		end
		hookCharacterDeath(player, character)
		applySpawnProtection(player, character)
	end
end

function SpawnManager.SpawnPlayers(players)
	for _, player in ipairs(players) do
		if player and player.Parent then
			SpawnManager.SpawnPlayer(player)
		end
	end
end

function SpawnManager.CancelRespawn(player)
	respawnTokens[player.UserId] = nil
end

return SpawnManager
