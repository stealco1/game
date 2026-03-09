local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Systems = ServerScriptService:WaitForChild("Systems")
local UIStateManager = require(Systems:WaitForChild("UIStateManager"):WaitForChild("UIStateManager"))
local PlayerManager = require(Systems:WaitForChild("PlayerManager"):WaitForChild("PlayerManager"))
local SpawnManager = require(Systems:WaitForChild("SpawnManager"):WaitForChild("SpawnManager"))
local EconomyManager = require(Systems:WaitForChild("EconomyManager"):WaitForChild("EconomyManager"))
require(Systems:WaitForChild("ShopManager"):WaitForChild("ShopManager"))

local MapManager = require(ServerScriptService:WaitForChild("MapManager"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local UIRemotes = Remotes:WaitForChild("UIRemotes")
local MatchEvents = Remotes:WaitForChild("MatchEvents")

local function ensureRemote(folder, name)
	local r = folder:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = folder
	return r
end

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if f and f:IsA("Folder") then return f end
	if f then f:Destroy() end
	f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local PlayGameRemote = UIRemotes:WaitForChild("PlayGame")
local SelectTeamRemote = UIRemotes:WaitForChild("SelectTeam")
local RequestTeamSwitchMenuRemote = ensureRemote(UIRemotes, "RequestTeamSwitchMenu")
local RequestMainMenuRemote = ensureRemote(UIRemotes, "RequestMainMenu")
local SubmitMapVoteLegacy = ensureRemote(UIRemotes, "SubmitMapVote")
local TeamSelectStart = MatchEvents:WaitForChild("TeamSelectStart")
local CountdownStart = MatchEvents:WaitForChild("CountdownStart")
local TeamCounts = MatchEvents:WaitForChild("TeamCounts")
local ScoreUpdate = MatchEvents:WaitForChild("ScoreUpdate")
local RoundResult = MatchEvents:WaitForChild("RoundResult")
local MatchTimerUpdate = MatchEvents:WaitForChild("MatchTimerUpdate")
local MatchStart = MatchEvents:WaitForChild("MatchStart")
local MatchEnd = MatchEvents:WaitForChild("MatchEnd")
local ReturnToLobbyRemote = ensureRemote(MatchEvents, "ReturnToLobby")
local MapVoteStartLegacy = ensureRemote(MatchEvents, "MapVoteStart")
local MapVoteUpdateLegacy = ensureRemote(MatchEvents, "MapVoteUpdate")

local RemoteEvents = ensureFolder(ReplicatedStorage, "RemoteEvents")
local StartMapVote = ensureRemote(RemoteEvents, "StartMapVote")
local SubmitMapVote = ensureRemote(RemoteEvents, "SubmitMapVote")
local UpdateVoteCounts = ensureRemote(RemoteEvents, "UpdateVoteCounts")
local EndMapVote = ensureRemote(RemoteEvents, "EndMapVote")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KillSignal = Shared:WaitForChild("KillSignal")
local AssistSignal = Shared:WaitForChild("AssistSignal")

local COUNTDOWN_DURATION = 5
local TEAM_SELECT_DURATION = 10
local MAP_VOTE_DURATION = 10
local MATCH_DURATION = 180
local ENDING_DURATION = 5
local TEAM_KILL_TARGET = 20
local TEAM_SWITCH_COOLDOWN_PLAYING = 8

local TEAM_NAMES = {"Pink", "Purple"}

local state = "Loading"
local roundToken = 0
local selectedTeams = {}
local playerStats = {}
local teamScores = {Pink = 0, Purple = 0}
local matchEndsAt = 0
local teamSelectEndsAt = 0
local mapVoteEndsAt = 0
local countdownEndsAt = 0
local lastTeamSwitchAt = {}
local pendingTeamSwitch = {}
local voteCandidates = {}
local votesByUserId = {}
local voteCounts = {}
local voteEndsAt = 0
local selectedMapName = ""
local hasRoundStartedOnce = false
local lobbyAutoStartNonce = 0
local LOBBY_AUTO_START_DELAY = 4
local scheduleLobbyAutoStart = function() end
Players.CharacterAutoLoads = false
MapManager.Initialize()

local function remainingSeconds(endAt)
	if endAt <= 0 then return 0 end
	return math.max(0, math.ceil(endAt - os.clock()))
end

local function setState(nextState)
	state = nextState
	UIStateManager.SetState(nextState)
	PlayerManager.ApplyStateAll(Players:GetPlayers(), nextState)
end

local function clearAllPlayersToMenu()
	for _, player in ipairs(Players:GetPlayers()) do
		SpawnManager.CancelRespawn(player)
		SpawnManager.ClearPlayer(player)
	end
end

local function getTeamCountsExcluding(playerToExclude)
	local counts = {Pink = 0, Purple = 0}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= playerToExclude then
			local teamName = selectedTeams[p.UserId] or SpawnManager.GetAssignedTeam(p)
			if teamName == "Pink" or teamName == "Purple" then
				counts[teamName] += 1
			end
		end
	end
	return counts
end

local function canAssignTeam(player, targetTeam)
	if targetTeam ~= "Pink" and targetTeam ~= "Purple" then
		return false
	end
	local counts = getTeamCountsExcluding(player)
	counts[targetTeam] += 1
	local diff = math.abs(counts.Pink - counts.Purple)
	return diff <= 1
end

local function smallerTeam(counts)
	if counts.Pink <= counts.Purple then
		return "Pink"
	end
	return "Purple"
end

local function broadcastTeamCounts(cooldownByUserId)
	local counts = getTeamCountsExcluding(nil)
	for _, player in ipairs(Players:GetPlayers()) do
		local cooldown = 0
		if typeof(cooldownByUserId) == "table" then
			cooldown = math.max(0, math.floor(tonumber(cooldownByUserId[player.UserId]) or 0))
		end
		TeamCounts:FireClient(player, {
			Pink = counts.Pink,
			Purple = counts.Purple,
			YourTeam = selectedTeams[player.UserId] or SpawnManager.GetAssignedTeam(player) or "Auto",
			SwitchCooldown = cooldown,
		})
	end
end

local function ensureAssignedTeamsBalanced()
	local counts = getTeamCountsExcluding(nil)
	for _, player in ipairs(Players:GetPlayers()) do
		if not selectedTeams[player.UserId] then
			local teamName = smallerTeam(counts)
			selectedTeams[player.UserId] = teamName
			SpawnManager.AssignTeam(player, teamName)
			counts[teamName] += 1
		end
	end
end

local function resetRoundStats()
	playerStats = {}
	teamScores = {Pink = 0, Purple = 0}
	for _, player in ipairs(Players:GetPlayers()) do
		playerStats[player.UserId] = {Kills = 0, Deaths = 0, Assists = 0}
		player:SetAttribute("RoundKills", 0)
		player:SetAttribute("RoundDeaths", 0)
		player:SetAttribute("RoundAssists", 0)
	end
end

local function buildScoreRows()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = playerStats[player.UserId] or {Kills = 0, Deaths = 0, Assists = 0}
		local kills = tonumber(stats.Kills) or 0
		local deaths = tonumber(stats.Deaths) or 0
		local assists = tonumber(stats.Assists) or 0
		local kd = kills / math.max(1, deaths)
		local score = (kills * 100) + (assists * 30) - (deaths * 10)
		rows[#rows + 1] = {
			UserId = player.UserId,
			Name = player.DisplayName ~= "" and player.DisplayName or player.Name,
			Team = SpawnManager.GetAssignedTeam(player) or "Unassigned",
			Kills = kills,
			Deaths = deaths,
			Assists = assists,
			KD = kd,
			Score = score,
		}
	end
	table.sort(rows, function(a, b)
		if a.Score ~= b.Score then return a.Score > b.Score end
		if a.Kills ~= b.Kills then return a.Kills > b.Kills end
		if a.Deaths ~= b.Deaths then return a.Deaths < b.Deaths end
		return a.Name < b.Name
	end)
	return rows
end

local function broadcastScoreUpdate()
	ScoreUpdate:FireAllClients({
		TeamScores = {Pink = teamScores.Pink, Purple = teamScores.Purple},
		PlayerStats = playerStats,
		Rows = buildScoreRows(),
		TargetKills = TEAM_KILL_TARGET,
	})
end

local function pickWinnerFromTeam(winnerTeam)
	if winnerTeam ~= "Pink" and winnerTeam ~= "Purple" then
		return nil
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if SpawnManager.GetAssignedTeam(player) == winnerTeam then
			return player
		end
	end
	return nil
end

local function clearVotes()
	voteCandidates = {}
	votesByUserId = {}
	voteCounts = {}
	voteEndsAt = 0
end

local function votePayload()
	return {
		Candidates = voteCandidates,
		Counts = voteCounts,
		Votes = votesByUserId,
		TimeRemaining = remainingSeconds(voteEndsAt),
	}
end
local function fireVoteStart(target)
	local payload = {
		Candidates = voteCandidates,
		Duration = remainingSeconds(voteEndsAt),
		EndsAt = voteEndsAt,
	}
	if target then
		StartMapVote:FireClient(target, payload)
		MapVoteStartLegacy:FireClient(target, payload)
	else
		print("[Voting] Vote started")
		StartMapVote:FireAllClients(payload)
		MapVoteStartLegacy:FireAllClients(payload)
	end
end

local function fireVoteCounts(target)
	local payload = votePayload()
	if target then
		UpdateVoteCounts:FireClient(target, payload)
		MapVoteUpdateLegacy:FireClient(target, payload)
	else
		UpdateVoteCounts:FireAllClients(payload)
		MapVoteUpdateLegacy:FireAllClients(payload)
	end
end

local function setupVoteCandidates()
	clearVotes()
	local allMaps = MapManager.GetMapNames()
	if #allMaps == 0 then
		return
	end

	local pool = {}
	if #allMaps <= 3 then
		for _, name in ipairs(allMaps) do
			table.insert(pool, name)
		end
	else
		pool = MapManager.GetEligibleMaps()
		if #pool == 0 then
			for _, name in ipairs(allMaps) do
				table.insert(pool, name)
			end
		end
	end

	local temp = {}
	for _, name in ipairs(pool) do temp[#temp + 1] = name end
	while #voteCandidates < math.min(3, #temp) do
		local idx = math.random(1, #temp)
		table.insert(voteCandidates, temp[idx])
		table.remove(temp, idx)
	end
	for _, name in ipairs(voteCandidates) do
		voteCounts[name] = 0
	end
	print("[Voting] Candidates: " .. table.concat(voteCandidates, ", "))
	voteEndsAt = os.clock() + MAP_VOTE_DURATION
	fireVoteStart(nil)
	fireVoteCounts(nil)
end

local function resolveWinningVote()
	if #voteCandidates == 0 then
		return MapManager.GetRandomMap()
	end
	local bestCount = -1
	local winners = {}
	for _, name in ipairs(voteCandidates) do
		local c = tonumber(voteCounts[name]) or 0
		if c > bestCount then
			bestCount = c
			winners = {name}
		elseif c == bestCount then
			table.insert(winners, name)
		end
	end
	if #winners == 0 then
		winners = voteCandidates
	end
	local winner = winners[math.random(1, #winners)]

	if winner == MapManager.LastMapName and #voteCandidates > 1 then
		local altBest = -1
		local alternatives = {}
		for _, name in ipairs(voteCandidates) do
			if name ~= MapManager.LastMapName then
				local c = tonumber(voteCounts[name]) or 0
				if c > altBest then
					altBest = c
					alternatives = {name}
				elseif c == altBest then
					table.insert(alternatives, name)
				end
			end
		end
		if #alternatives > 0 then
			winner = alternatives[math.random(1, #alternatives)]
		end
	end

	print("[Voting] Vote ended")
	print("[Voting] Winner: " .. tostring(winner))
	EndMapVote:FireAllClients({Winner = winner, Counts = voteCounts})
	return winner
end

local function enterLobby(manualReturn)
	setState("Lobby")
	matchEndsAt = 0
	teamSelectEndsAt = 0
	mapVoteEndsAt = 0
	countdownEndsAt = 0
	MatchTimerUpdate:FireAllClients(0)
	selectedTeams = {}
	lastTeamSwitchAt = {}
	pendingTeamSwitch = {}
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("AssignedTeam", "")
		player:SetAttribute("TeamSwitchPending", false)
		player:SetAttribute("IsInMenu", true)
		player:SetAttribute("IsInMatch", false)
		player:SetAttribute("IsAlive", false)
	end
	clearVotes()
	MapManager.UnloadCurrentMap()
	clearAllPlayersToMenu()
	broadcastScoreUpdate()
	RoundResult:FireAllClients({WinnerTeam = "", TeamScores = {Pink = 0, Purple = 0}, ToLobby = true})
	if not manualReturn then
		scheduleLobbyAutoStart()
	end
end

local function beginEnding(myToken, winnerTeam)
	if myToken ~= roundToken then return end
	if state == "Ending" then return end
	setState("Ending")
	matchEndsAt = 0
	MatchTimerUpdate:FireAllClients(0)

	local players = Players:GetPlayers()
	local winnerPlayer = pickWinnerFromTeam(winnerTeam)
	EconomyManager.AwardMatchResults(players, winnerPlayer)
	RoundResult:FireAllClients({
		WinnerTeam = winnerTeam or "",
		TeamScores = {Pink = teamScores.Pink, Purple = teamScores.Purple},
		ToLobby = false,
	})
	MatchEnd:FireAllClients({WinnerTeam = winnerTeam or "", MapName = selectedMapName})

	task.delay(ENDING_DURATION, function()
		if myToken ~= roundToken then return end
		enterLobby(false)
	end)
end

local function beginPlaying(myToken)
	if myToken ~= roundToken then return end
	if not MapManager.GetCurrentMap() then
		warn("[MapManager] CurrentMap nil before Playing, loading fallback")
		local fallback = selectedMapName ~= "" and selectedMapName or MapManager.GetRandomMap()
		MapManager.LoadMap(fallback)
	end
	assert(MapManager.GetCurrentMap() ~= nil, "CurrentMap is never nil during active match")

	setState("Playing")
	resetRoundStats()
	broadcastScoreUpdate()
	SpawnManager.SpawnPlayers(Players:GetPlayers())
	matchEndsAt = os.clock() + MATCH_DURATION
	MatchTimerUpdate:FireAllClients(MATCH_DURATION)
	MatchStart:FireAllClients({MapName = selectedMapName, Duration = MATCH_DURATION})

	task.spawn(function()
		while true do
			if myToken ~= roundToken or state ~= "Playing" then return end
			local remaining = remainingSeconds(matchEndsAt)
			MatchTimerUpdate:FireAllClients(remaining)
			if remaining <= 0 then
				local winner
				if teamScores.Pink > teamScores.Purple then
					winner = "Pink"
				elseif teamScores.Purple > teamScores.Pink then
					winner = "Purple"
				else
					winner = TEAM_NAMES[math.random(1, #TEAM_NAMES)]
				end
				beginEnding(myToken, winner)
				return
			end
			task.wait(1)
		end
	end)
end

local function beginCountdown(myToken, votedMap)
	if myToken ~= roundToken then return end
	clearAllPlayersToMenu()
	selectedMapName = (typeof(votedMap) == "string" and votedMap ~= "") and votedMap or (MapManager.GetRandomMap() or "")
	if selectedMapName == "" then
		warn("[MapManager] No map selected for countdown")
		enterLobby()
		return
	end
	local loaded = MapManager.LoadMap(selectedMapName)
	if not loaded then
		warn("[MapManager] Failed to load voted map, returning to lobby")
		enterLobby()
		return
	end

	setState("Countdown")
	countdownEndsAt = os.clock() + COUNTDOWN_DURATION
	CountdownStart:FireAllClients(COUNTDOWN_DURATION)
	task.delay(COUNTDOWN_DURATION, function()
		if myToken ~= roundToken or state ~= "Countdown" then return end
		beginPlaying(myToken)
	end)
end

local function beginMapVote(myToken)
	if myToken ~= roundToken then return end
	setState("MapVote")
	mapVoteEndsAt = os.clock() + MAP_VOTE_DURATION
	setupVoteCandidates()
	task.delay(MAP_VOTE_DURATION, function()
		if myToken ~= roundToken or state ~= "MapVote" then return end
		local votedMap = resolveWinningVote()
		beginCountdown(myToken, votedMap)
	end)
end

local function beginTeamSelect(myToken)
	if myToken ~= roundToken then return end
	hasRoundStartedOnce = true
	selectedTeams = {}
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("AssignedTeam", "")
		player:SetAttribute("TeamSwitchPending", false)
		pendingTeamSwitch[player.UserId] = nil
	end
	clearAllPlayersToMenu()
	setState("TeamSelect")
	teamSelectEndsAt = os.clock() + TEAM_SELECT_DURATION
	TeamSelectStart:FireAllClients(TEAM_SELECT_DURATION)
	broadcastTeamCounts()
	task.delay(TEAM_SELECT_DURATION, function()
		if myToken ~= roundToken or state ~= "TeamSelect" then return end
		ensureAssignedTeamsBalanced()
		broadcastTeamCounts()
		beginMapVote(myToken)
	end)
end
scheduleLobbyAutoStart = function()
	lobbyAutoStartNonce += 1
	local nonce = lobbyAutoStartNonce
	task.delay(LOBBY_AUTO_START_DELAY, function()
		if nonce ~= lobbyAutoStartNonce then return end
		if state ~= "Lobby" then return end
		if not hasRoundStartedOnce then return end
		if #Players:GetPlayers() <= 0 then return end
		roundToken += 1
		beginTeamSelect(roundToken)
	end)
end

PlayGameRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	if state == "Lobby" then
		roundToken += 1
		local myToken = roundToken
		beginTeamSelect(myToken)
	end
end)

ReturnToLobbyRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	if state == "Lobby" then return end
	roundToken += 1
	enterLobby(true)
end)

RequestMainMenuRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	if state == "Loading" then return end

	SpawnManager.CancelRespawn(player)
	SpawnManager.ClearPlayer(player)
	pendingTeamSwitch[player.UserId] = nil
	player:SetAttribute("TeamSwitchPending", false)
	player:SetAttribute("IsInMenu", true)
	player:SetAttribute("IsInMatch", false)
	player:SetAttribute("IsAlive", false)

	if state == "Playing" then
		broadcastTeamCounts()
		broadcastScoreUpdate()
	end
end)

local function handleVoteSubmission(player, mapName)
	if state ~= "MapVote" then return end
	if MapManager.GetCurrentMap() ~= nil then return end
	if typeof(mapName) ~= "string" then return end
	if voteCounts[mapName] == nil then return end
	local prev = votesByUserId[player.UserId]
	if prev and voteCounts[prev] then
		voteCounts[prev] = math.max(0, voteCounts[prev] - 1)
	end
	votesByUserId[player.UserId] = mapName
	voteCounts[mapName] = (voteCounts[mapName] or 0) + 1
	fireVoteCounts(nil)
end

SubmitMapVoteLegacy.OnServerEvent:Connect(handleVoteSubmission)
SubmitMapVote.OnServerEvent:Connect(handleVoteSubmission)

RequestTeamSwitchMenuRemote.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	if state ~= "Playing" then return end

	local now = os.clock()
	local lastSwitch = lastTeamSwitchAt[player.UserId] or 0
	local remaining = TEAM_SWITCH_COOLDOWN_PLAYING - (now - lastSwitch)
	if remaining > 0 then
		broadcastTeamCounts({[player.UserId] = math.ceil(remaining)})
		return
	end

	lastTeamSwitchAt[player.UserId] = now
	pendingTeamSwitch[player.UserId] = true
	player:SetAttribute("TeamSwitchPending", true)
	player:SetAttribute("IsInMenu", true)
	player:SetAttribute("IsInMatch", false)
	player:SetAttribute("IsAlive", false)
	SpawnManager.CancelRespawn(player)
	SpawnManager.ClearPlayer(player)
	broadcastTeamCounts()
end)

SelectTeamRemote.OnServerEvent:Connect(function(player, requestedTeam)
	if state ~= "TeamSelect" and state ~= "Lobby" and state ~= "Playing" then return end
	if typeof(requestedTeam) ~= "string" then return end
	if requestedTeam ~= "Pink" and requestedTeam ~= "Purple" then return end
	if not canAssignTeam(player, requestedTeam) then return end

	if state == "Playing" then
		if pendingTeamSwitch[player.UserId] ~= true and player:GetAttribute("TeamSwitchPending") ~= true then
			return
		end
	end

	selectedTeams[player.UserId] = requestedTeam
	SpawnManager.AssignTeam(player, requestedTeam)
	if state == "Playing" then
		pendingTeamSwitch[player.UserId] = nil
		player:SetAttribute("TeamSwitchPending", false)
		player:SetAttribute("IsInMenu", false)
		player:SetAttribute("IsInMatch", true)
		SpawnManager.CancelRespawn(player)
		SpawnManager.SpawnPlayer(player)
	else
		pendingTeamSwitch[player.UserId] = nil
		player:SetAttribute("TeamSwitchPending", false)
	end
	broadcastTeamCounts()
	broadcastScoreUpdate()
end)

KillSignal.Event:Connect(function(killerPlayer, victimPlayer)
	if state ~= "Playing" then return end
	if victimPlayer and victimPlayer.Parent then
		local vs = playerStats[victimPlayer.UserId] or {Kills = 0, Deaths = 0, Assists = 0}
		vs.Deaths += 1
		playerStats[victimPlayer.UserId] = vs
		victimPlayer:SetAttribute("RoundDeaths", vs.Deaths)
	end
	if killerPlayer and killerPlayer.Parent and victimPlayer and victimPlayer.Parent and killerPlayer ~= victimPlayer then
		local ks = playerStats[killerPlayer.UserId] or {Kills = 0, Deaths = 0, Assists = 0}
		ks.Kills += 1
		playerStats[killerPlayer.UserId] = ks
		killerPlayer:SetAttribute("RoundKills", ks.Kills)
		local killerTeam = SpawnManager.GetAssignedTeam(killerPlayer)
		if killerTeam == "Pink" or killerTeam == "Purple" then
			teamScores[killerTeam] += 1
		end
	end
	broadcastScoreUpdate()
	if teamScores.Pink >= TEAM_KILL_TARGET then
		beginEnding(roundToken, "Pink")
	elseif teamScores.Purple >= TEAM_KILL_TARGET then
		beginEnding(roundToken, "Purple")
	end
end)

AssistSignal.Event:Connect(function(assisterPlayer)
	if state ~= "Playing" then return end
	if not assisterPlayer or not assisterPlayer.Parent then return end
	local as = playerStats[assisterPlayer.UserId] or {Kills = 0, Deaths = 0, Assists = 0}
	as.Assists += 1
	playerStats[assisterPlayer.UserId] = as
	assisterPlayer:SetAttribute("RoundAssists", as.Assists)
	broadcastScoreUpdate()
end)

Players.PlayerAdded:Connect(function(player)
	EconomyManager.TrackPlayer(player)
	PlayerManager.TrackPlayer(player)
	PlayerManager.ApplyState(player, state)
	UIStateManager.SyncPlayer(player)
	player:SetAttribute("TeamSwitchPending", false)
	pendingTeamSwitch[player.UserId] = nil

	if state == "Playing" then
		selectedTeams[player.UserId] = smallerTeam(getTeamCountsExcluding(nil))
		SpawnManager.AssignTeam(player, selectedTeams[player.UserId])
		playerStats[player.UserId] = {Kills = 0, Deaths = 0, Assists = 0}
		task.delay(1.5, function()
			if player.Parent and state == "Playing" then
				SpawnManager.SpawnPlayer(player)
				broadcastScoreUpdate()
				MatchTimerUpdate:FireClient(player, remainingSeconds(matchEndsAt))
			end
		end)
	elseif state == "TeamSelect" then
		task.defer(function()
			if not player.Parent then return end
			SpawnManager.ClearPlayer(player)
			selectedTeams[player.UserId] = smallerTeam(getTeamCountsExcluding(nil))
			SpawnManager.AssignTeam(player, selectedTeams[player.UserId])
			TeamSelectStart:FireClient(player, remainingSeconds(teamSelectEndsAt))
			broadcastTeamCounts()
		end)
	elseif state == "MapVote" then
		task.defer(function()
			if not player.Parent then return end
			SpawnManager.ClearPlayer(player)
			selectedTeams[player.UserId] = smallerTeam(getTeamCountsExcluding(nil))
			SpawnManager.AssignTeam(player, selectedTeams[player.UserId])
			if MapManager.GetCurrentMap() ~= nil then
				return
			end
			fireVoteStart(player)
			fireVoteCounts(player)
		end)
	elseif state == "Countdown" then
		task.defer(function()
			if not player.Parent then return end
			SpawnManager.ClearPlayer(player)
			selectedTeams[player.UserId] = smallerTeam(getTeamCountsExcluding(nil))
			SpawnManager.AssignTeam(player, selectedTeams[player.UserId])
			CountdownStart:FireClient(player, remainingSeconds(countdownEndsAt))
		end)
	else
		task.defer(function()
			if player.Parent then
				SpawnManager.ClearPlayer(player)
			end
		end)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	EconomyManager.RemovePlayer(player)
	selectedTeams[player.UserId] = nil
	playerStats[player.UserId] = nil
	lastTeamSwitchAt[player.UserId] = nil
	pendingTeamSwitch[player.UserId] = nil
	local voted = votesByUserId[player.UserId]
	votesByUserId[player.UserId] = nil
	if voted and voteCounts[voted] then
		voteCounts[voted] = math.max(0, voteCounts[voted] - 1)
		fireVoteCounts(nil)
	end
	if state == "TeamSelect" or state == "MapVote" then
		broadcastTeamCounts()
	end
	if #Players:GetPlayers() <= 1 and (state == "Countdown" or state == "TeamSelect" or state == "MapVote" or state == "Playing") then
		roundToken += 1
		enterLobby(true)
	end
end)

setState("Loading")
enterLobby(true)

print("GameManager initialized")
