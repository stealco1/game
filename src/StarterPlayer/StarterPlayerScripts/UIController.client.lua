local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local uiRemotes = remotes:WaitForChild("UIRemotes")
local matchEvents = remotes:WaitForChild("MatchEvents")
local matchTimerUpdate = matchEvents:WaitForChild("MatchTimerUpdate")
local returnToLobbyRemote = matchEvents:WaitForChild("ReturnToLobby")
local mapVoteRemotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
local mapVoteStart = mapVoteRemotes and mapVoteRemotes:WaitForChild("StartMapVote") or matchEvents:WaitForChild("MapVoteStart")
local mapVoteUpdate = mapVoteRemotes and mapVoteRemotes:WaitForChild("UpdateVoteCounts") or matchEvents:WaitForChild("MapVoteUpdate")
local assistAwarded = matchEvents:WaitForChild("AssistAwarded")
local submitMapVote = mapVoteRemotes and mapVoteRemotes:WaitForChild("SubmitMapVote") or uiRemotes:WaitForChild("SubmitMapVote")
local requestTeamSwitchMenuRemote = uiRemotes:WaitForChild("RequestTeamSwitchMenu")
local requestMainMenuRemote = uiRemotes:WaitForChild("RequestMainMenu")
local gameStateValue = shared:WaitForChild("GameState")
local clientAction = shared:WaitForChild("ClientAction")
local shopData = require(shared:WaitForChild("ShopData"))
local function shouldShowMapVoteUI()
	if gameStateValue.Value ~= "MapVote" then return false end
	if workspace:FindFirstChild("CurrentMap") then return false end
	return true
end

local function ensureGui(name)
	local existing = playerGui:FindFirstChild(name)
	if existing then return existing end
	local template = StarterGui:FindFirstChild(name)
	if template and template:IsA("LayerCollector") then
		local clone = template:Clone()
		clone.ResetOnSpawn = false
		clone.Parent = playerGui
		return clone
	end
	return nil
end

local mainUI = ensureGui("MainUI")
local loadingScreen = ensureGui("LoadingScreen")
local hud = ensureGui("HUD")
local mobileControls = ensureGui("MobileControls")
local teamSelectGui = ensureGui("TeamSelectMenu")
local mapVoteGui = ensureGui("MapVoteMenu")
local countdownGui = ensureGui("RoundCountdown")
local respawnGui = ensureGui("RespawnUI")

if not (mainUI and loadingScreen and hud and teamSelectGui and mapVoteGui and countdownGui and respawnGui) then
	warn("UIController missing critical UI")
	return
end
local function disableDefaultPlayerList()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	end)
end

disableDefaultPlayerList()
task.delay(2, disableDefaultPlayerList)
player.CharacterAdded:Connect(function()
	task.defer(disableDefaultPlayerList)
	task.delay(1, disableDefaultPlayerList)
end)

local pages = mainUI:WaitForChild("Pages", 10)
if not pages then
	warn("UIController missing MainUI.Pages")
	return
end

local mainMenu = pages:FindFirstChild("MainMenu")
local loadoutMenu = pages:FindFirstChild("LoadoutMenu")
local shopMenu = pages:FindFirstChild("ShopMenu")
local settingsMenu = pages:FindFirstChild("SettingsMenu")
local serverBrowser = pages:FindFirstChild("ServerBrowser")
local lobbyMenu = pages:FindFirstChild("LobbyMenu")
local lobbyTitle = lobbyMenu and lobbyMenu:FindFirstChild("Title")
if lobbyTitle and lobbyTitle:IsA("TextLabel") then
	lobbyTitle.Text = ""
end
if not (mainMenu and loadoutMenu and shopMenu and settingsMenu and serverBrowser) then
	warn("UIController missing required menu pages")
	return
end

local buttons = mainMenu:FindFirstChild("ButtonContainer")
local playButton = buttons and buttons:FindFirstChild("PlayButton")
local loadoutButton = buttons and buttons:FindFirstChild("LoadoutButton")
local shopButton = buttons and buttons:FindFirstChild("ShopButton")
local settingsButton = buttons and buttons:FindFirstChild("SettingsButton")
local serversButton = buttons and buttons:FindFirstChild("ServersButton")

local slots = loadoutMenu:FindFirstChild("Slots")
local primarySlot = slots and slots:FindFirstChild("PrimarySlot")
local secondarySlot = slots and slots:FindFirstChild("SecondarySlot")
local meleeSlot = slots and slots:FindFirstChild("MeleeSlot")
local primaryText = primarySlot and primarySlot:FindFirstChild("TextLabel")
local secondaryText = secondarySlot and secondarySlot:FindFirstChild("TextLabel")
local meleeText = meleeSlot and meleeSlot:FindFirstChild("TextLabel")

local itemGrid = shopMenu:FindFirstChild("ItemGrid")
local shopCurrency = shopMenu:FindFirstChild("CurrencyDisplay")
local settingsList = settingsMenu:FindFirstChild("SettingsList")
local hudCurrency = hud:FindFirstChild("MoneyLabel")
local killFeedFrame = hud:FindFirstChild("KillFeed")
local legacyStatsLabel = hud:FindFirstChild("PersonalStatsLabel")
if legacyStatsLabel then
	legacyStatsLabel:Destroy()
end

if killFeedFrame then
	killFeedFrame.AnchorPoint = Vector2.new(1, 0)
	killFeedFrame.Position = UDim2.fromScale(0.985, 0.08)
	killFeedFrame.Size = UDim2.fromScale(0.25, 0.25)
	killFeedFrame.BackgroundTransparency = 1
	killFeedFrame.BorderSizePixel = 0
	killFeedFrame.ClipsDescendants = true
	killFeedFrame.ZIndex = math.max(killFeedFrame.ZIndex, 6)
	local existingLayout = killFeedFrame:FindFirstChildOfClass("UIListLayout")
	if existingLayout then
		existingLayout:Destroy()
	end
	for _, child in ipairs(killFeedFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local scoreLabel = hud:FindFirstChild("TeamScoreLabel")
if not scoreLabel then
	scoreLabel = Instance.new("TextLabel")
	scoreLabel.Name = "TeamScoreLabel"
	scoreLabel.AnchorPoint = Vector2.new(0.5, 0)
	scoreLabel.Position = UDim2.fromScale(0.5, 0.03)
	scoreLabel.Size = UDim2.fromScale(0.34, 0.07)
	scoreLabel.BackgroundTransparency = 0.35
	scoreLabel.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
	scoreLabel.BorderSizePixel = 0
	scoreLabel.Font = Enum.Font.GothamSemibold
	scoreLabel.TextScaled = true
	scoreLabel.TextColor3 = Color3.fromRGB(245, 235, 255)
	scoreLabel.Text = "Pink 0 | 0 Purple"
	scoreLabel.Parent = hud
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = scoreLabel
end

local matchTimerLabel = hud:FindFirstChild("MatchTimerLabel")
if not matchTimerLabel then
	matchTimerLabel = Instance.new("TextLabel")
	matchTimerLabel.Name = "MatchTimerLabel"
	matchTimerLabel.AnchorPoint = Vector2.new(0.5, 0)
	matchTimerLabel.Position = UDim2.fromScale(0.5, 0.11)
	matchTimerLabel.Size = UDim2.fromScale(0.18, 0.055)
	matchTimerLabel.BackgroundTransparency = 0.3
	matchTimerLabel.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
	matchTimerLabel.BorderSizePixel = 0
	matchTimerLabel.Font = Enum.Font.GothamSemibold
	matchTimerLabel.TextScaled = true
	matchTimerLabel.TextColor3 = Color3.fromRGB(246, 236, 255)
	matchTimerLabel.Text = "TIME 00:00"
	matchTimerLabel.Parent = hud
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 10)
	tc.Parent = matchTimerLabel
end

local scoreboardFrame = hud:FindFirstChild("Scoreboard")
local scoreboardRows
local scoreboardTeamButton
local scoreboardMainMenuButton
local function ensureScoreboard()
	if scoreboardFrame and scoreboardRows and scoreboardRows.Parent == scoreboardFrame then
		return
	end
	if not scoreboardFrame then
		scoreboardFrame = Instance.new("Frame")
		scoreboardFrame.Name = "Scoreboard"
		scoreboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		scoreboardFrame.Position = UDim2.fromScale(0.5, 0.5)
		scoreboardFrame.Size = UDim2.fromScale(0.62, 0.58)
		scoreboardFrame.BackgroundColor3 = Color3.fromRGB(26, 20, 40)
		scoreboardFrame.BackgroundTransparency = 0.2
		scoreboardFrame.BorderSizePixel = 0
		scoreboardFrame.Visible = false
		scoreboardFrame.Parent = hud

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = scoreboardFrame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(220, 198, 247)
		stroke.Transparency = 0.25
		stroke.Thickness = 1.3
		stroke.Parent = scoreboardFrame

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.04, 0.03)
		title.Size = UDim2.fromScale(0.92, 0.10)
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.TextColor3 = Color3.fromRGB(245, 236, 255)
		title.Text = "SCOREBOARD"
		title.Parent = scoreboardFrame

		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.BackgroundTransparency = 1
		header.Position = UDim2.fromScale(0.04, 0.14)
		header.Size = UDim2.fromScale(0.92, 0.07)
		header.Font = Enum.Font.Code
		header.TextScaled = true
		header.TextColor3 = Color3.fromRGB(220, 206, 244)
		header.TextXAlignment = Enum.TextXAlignment.Left
		header.Text = "Player | Team | K | D | A | K/D | Score"
		header.Parent = scoreboardFrame
	end

	scoreboardRows = scoreboardFrame:FindFirstChild("Rows")
	if not scoreboardRows then
		scoreboardRows = Instance.new("ScrollingFrame")
		scoreboardRows.Name = "Rows"
		scoreboardRows.BackgroundTransparency = 1
		scoreboardRows.Position = UDim2.fromScale(0.04, 0.23)
		scoreboardRows.Size = UDim2.fromScale(0.92, 0.73)
		scoreboardRows.CanvasSize = UDim2.fromOffset(0, 0)
		scoreboardRows.ScrollBarThickness = 6
		scoreboardRows.BorderSizePixel = 0
		scoreboardRows.Parent = scoreboardFrame

		local list = Instance.new("UIListLayout")
		list.Name = "List"
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 4)
		list.Parent = scoreboardRows

		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scoreboardRows.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 6)
		end)
	end

	scoreboardTeamButton = scoreboardFrame:FindFirstChild("SwitchTeamButton")
	if not scoreboardTeamButton then
		scoreboardTeamButton = Instance.new("TextButton")
		scoreboardTeamButton.Name = "SwitchTeamButton"
		scoreboardTeamButton.AnchorPoint = Vector2.new(1, 0)
		scoreboardTeamButton.Position = UDim2.fromScale(0.96, 0.04)
		scoreboardTeamButton.Size = UDim2.fromScale(0.2, 0.08)
		scoreboardTeamButton.BackgroundColor3 = Color3.fromRGB(110, 88, 152)
		scoreboardTeamButton.BackgroundTransparency = 0.15
		scoreboardTeamButton.BorderSizePixel = 0
		scoreboardTeamButton.Font = Enum.Font.GothamSemibold
		scoreboardTeamButton.TextScaled = true
		scoreboardTeamButton.TextColor3 = Color3.fromRGB(252, 245, 255)
		scoreboardTeamButton.Text = "Switch Team"
		scoreboardTeamButton.Parent = scoreboardFrame
		local switchCorner = Instance.new("UICorner")
		switchCorner.CornerRadius = UDim.new(0, 10)
		switchCorner.Parent = scoreboardTeamButton
	end

	scoreboardMainMenuButton = scoreboardFrame:FindFirstChild("MainMenuButton")
	if not scoreboardMainMenuButton then
		scoreboardMainMenuButton = Instance.new("TextButton")
		scoreboardMainMenuButton.Name = "MainMenuButton"
		scoreboardMainMenuButton.AnchorPoint = Vector2.new(1, 0)
		scoreboardMainMenuButton.Position = UDim2.fromScale(0.74, 0.04)
		scoreboardMainMenuButton.Size = UDim2.fromScale(0.2, 0.08)
		scoreboardMainMenuButton.BackgroundColor3 = Color3.fromRGB(110, 88, 152)
		scoreboardMainMenuButton.BackgroundTransparency = 0.15
		scoreboardMainMenuButton.BorderSizePixel = 0
		scoreboardMainMenuButton.Font = Enum.Font.GothamSemibold
		scoreboardMainMenuButton.TextScaled = true
		scoreboardMainMenuButton.TextColor3 = Color3.fromRGB(252, 245, 255)
		scoreboardMainMenuButton.Text = "Main Menu"
		scoreboardMainMenuButton.Parent = scoreboardFrame
		local menuCorner = Instance.new("UICorner")
		menuCorner.CornerRadius = UDim.new(0, 10)
		menuCorner.Parent = scoreboardMainMenuButton
	end
end

ensureScoreboard()

local shopFeedback = shopMenu:FindFirstChild("Feedback")
if not shopFeedback then
	shopFeedback = Instance.new("TextLabel")
	shopFeedback.Name = "Feedback"
	shopFeedback.BackgroundTransparency = 1
	shopFeedback.Size = UDim2.fromScale(0.9, 0.08)
	shopFeedback.Position = UDim2.fromScale(0.05, 0.18)
	shopFeedback.Font = Enum.Font.GothamSemibold
	shopFeedback.TextScaled = true
	shopFeedback.TextColor3 = Color3.fromRGB(255, 240, 250)
	shopFeedback.Text = ""
	shopFeedback.Parent = shopMenu
end

local tsRoot = teamSelectGui:FindFirstChild("Root")
local tsPanel = tsRoot and tsRoot:FindFirstChild("Panel")
local tsTimer = tsPanel and tsPanel:FindFirstChild("TimerLabel")
local tsYourTeam = tsPanel and tsPanel:FindFirstChild("YourTeamLabel")
local tsPink = tsPanel and tsPanel:FindFirstChild("PinkButton")
local tsPurple = tsPanel and tsPanel:FindFirstChild("PurpleButton")
local tsPinkCount = tsPink and tsPink:FindFirstChild("Count")
local tsPurpleCount = tsPurple and tsPurple:FindFirstChild("Count")

local mvRoot = mapVoteGui and mapVoteGui:FindFirstChild("Root")
local mvPanel = mvRoot and mvRoot:FindFirstChild("Panel")
local mvTimer = mvPanel and mvPanel:FindFirstChild("TimerLabel")
local mapVoteFrame = mvPanel and mvPanel:FindFirstChild("MapVoteFrame")
if mvPanel and not mapVoteFrame then
	mapVoteFrame = Instance.new("Frame")
	mapVoteFrame.Name = "MapVoteFrame"
	mapVoteFrame.AnchorPoint = Vector2.new(0.5, 1)
	mapVoteFrame.Position = UDim2.fromScale(0.5, 0.93)
	mapVoteFrame.Size = UDim2.fromScale(0.94, 0.62)
	mapVoteFrame.BackgroundTransparency = 1
	mapVoteFrame.Parent = mvPanel
	local voteLayout = Instance.new("UIListLayout")
	voteLayout.FillDirection = Enum.FillDirection.Horizontal
	voteLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	voteLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	voteLayout.Padding = UDim.new(0.02, 0)
	voteLayout.Parent = mapVoteFrame
end

local mapVoteButtons = {}
local mapVoteSelected = ""

local function refreshMapVoteButtons(payload)
	if not mapVoteFrame then return end
	if typeof(payload) ~= "table" then return end
	local counts = payload.Counts or {}
	for _, child in ipairs(mapVoteFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	table.clear(mapVoteButtons)
	for _, mapName in ipairs(payload.Candidates or {}) do
		local b = Instance.new("TextButton")
		b.Name = "Vote_" .. mapName
		b.Size = UDim2.fromScale(0.31, 1)
		b.BackgroundColor3 = Color3.fromRGB(108, 83, 145)
		b.BackgroundTransparency = 0.15
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.TextColor3 = Color3.fromRGB(252, 245, 255)
		b.Text = string.format("%s%sVotes: %d", mapName, string.char(10), tonumber(counts[mapName]) or 0)
		b.Parent = mapVoteFrame
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 10)
		bc.Parent = b
		b.Activated:Connect(function()
			mapVoteSelected = mapName
			submitMapVote:FireServer(mapName)
		end)
		mapVoteButtons[mapName] = b
	end
end

local function updateVoteCounts(payload)
	if typeof(payload) ~= "table" then return end
	local counts = payload.Counts or {}
	for mapName, button in pairs(mapVoteButtons) do
		if button and button.Parent then
			local c = tonumber(counts[mapName]) or 0
			button.Text = string.format("%s%sVotes: %d", mapName, string.char(10), c)
			button.BackgroundColor3 = (mapVoteSelected == mapName) and Color3.fromRGB(147, 114, 194) or Color3.fromRGB(108, 83, 145)
		end
	end
end

local cdRoot = countdownGui:FindFirstChild("Root")
local cdLabel = cdRoot and cdRoot:FindFirstChild("CountdownLabel")

local rsRoot = respawnGui:FindFirstChild("Root")
local rsLabel = rsRoot and rsRoot:FindFirstChild("RespawnLabel")

local loadoutState = {
	OwnedWeapons = {Primary = {}, Secondary = {}, Melee = {}},
	EquippedPrimary = "Rifle",
	EquippedSecondary = "Pistol",
	EquippedMelee = "Knife",
}

local currentState = "Loading"
local currentCoins = 0
local scoreboardOpen = false
local coinTweenValue = Instance.new("NumberValue")
coinTweenValue.Value = 0
local tsClose = tsPanel and tsPanel:FindFirstChild("CloseButton")
if tsPanel and not tsClose then
	tsClose = Instance.new("TextButton")
	tsClose.Name = "CloseButton"
	tsClose.AnchorPoint = Vector2.new(1, 0)
	tsClose.Position = UDim2.fromScale(0.98, 0.02)
	tsClose.Size = UDim2.fromScale(0.12, 0.14)
	tsClose.BackgroundColor3 = Color3.fromRGB(120, 96, 168)
	tsClose.BackgroundTransparency = 0.12
	tsClose.BorderSizePixel = 0
	tsClose.Font = Enum.Font.GothamBold
	tsClose.Text = "X"
	tsClose.TextScaled = true
	tsClose.TextColor3 = Color3.fromRGB(252, 245, 255)
	tsClose.Parent = tsPanel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = tsClose
end
local activeCoinTween = nil
local shopCards = {}
local purchasePending = {}
local TEAM_SWITCH_CLIENT_DEBOUNCE = 0.25
local lastTeamSwitchRequestAt = 0
local MAX_KILL_FEED_ENTRIES = 5
local KILL_FEED_ENTRY_LIFETIME = 4
local killFeedEntries = {}
local damageNumbersEnabled = false
local isMobileClient = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local mouseSensitivity = 1
local showKillFeedEnabled = true
local loadoutSelectorPanel = nil
local loadoutSelectorList = nil
local loadoutSelectorTitle = nil
local loadoutSelectorSlot = nil
player:SetAttribute("ForceMenuMouseUnlock", false)
local function listHas(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then return true end
	end
	return false
end

local function hideAllPages()
	for _, child in ipairs(pages:GetChildren()) do
		if child:IsA("Frame") then
			child.Visible = false
		end
	end
end

local function showMenu(frame)
	hideAllPages()
	if frame then frame.Visible = true end
	if loadoutSelectorPanel and frame ~= loadoutMenu then
		loadoutSelectorPanel.Visible = false
		loadoutSelectorSlot = nil
	end
end

local function canOpenTeamSwitchMenu()
	return currentState == "Playing" or currentState == "Lobby" or currentState == "TeamSelect"
end

local function setMouseMenuOverride(unlock)
	player:SetAttribute("ForceMenuMouseUnlock", unlock == true)
	if unlock then
		clientAction:Fire("ForceUnlockMouse")
	else
		clientAction:Fire("ReleaseMouseOverride")
	end
end

local function forceMenuMouseUnlock()
	setMouseMenuOverride(true)
	local function apply()
		pcall(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	end
	apply()
	task.defer(apply)
	task.delay(0.05, apply)
	task.delay(0.15, apply)
end

local function requestMainMenuReturn()
	forceMenuMouseUnlock()
	if requestMainMenuRemote then
		requestMainMenuRemote:FireServer()
	end
end
local function openTeamSelectMenuForSwitch()
	if not canOpenTeamSwitchMenu() then return end
	teamSelectGui.Enabled = true
	forceMenuMouseUnlock()
	if currentState == "Playing" and requestTeamSwitchMenuRemote then
		requestTeamSwitchMenuRemote:FireServer()
	end
	if currentState ~= "TeamSelect" and tsTimer then
		tsTimer.Text = "Switch Team"
	end
end

local function closeTeamSelectMenuIfManual()
	if currentState == "TeamSelect" or currentState == "Playing" then return end
	teamSelectGui.Enabled = false
	setMouseMenuOverride(false)
end
local function requestTeamSwitch(teamName)
	if not canOpenTeamSwitchMenu() then return end
	local now = os.clock()
	if now - lastTeamSwitchRequestAt < TEAM_SWITCH_CLIENT_DEBOUNCE then return end
	lastTeamSwitchRequestAt = now
	uiRemotes.SelectTeam:FireServer(teamName)
	if currentState == "TeamSelect" then
		teamSelectGui.Enabled = true
		forceMenuMouseUnlock()
	else
		teamSelectGui.Enabled = false
		if currentState ~= "Playing" then
			setMouseMenuOverride(false)
		end
	end
end

local function setMobileEnabled(enabled)
	local mc = playerGui:FindFirstChild("MobileControls") or mobileControls
	if mc then mc.Enabled = enabled end
end

local function formatCoins(value)
	return string.format("$%d", math.floor(value + 0.5))
end

local function formatMatchTime(totalSeconds)
	local clamped = math.max(0, math.floor(tonumber(totalSeconds) or 0))
	local minutes = math.floor(clamped / 60)
	local seconds = clamped % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function applyCurrencyText(value)
	if hudCurrency then
		hudCurrency.Text = formatCoins(value)
	end
	if shopCurrency then
		shopCurrency.Text = "Coins: " .. formatCoins(value)
	end
end

coinTweenValue.Changed:Connect(function(v)
	applyCurrencyText(v)
end)

local function animateCoins(target)
	target = math.max(0, math.floor(target or 0))
	currentCoins = target
	if activeCoinTween then activeCoinTween:Cancel() end
	activeCoinTween = TweenService:Create(coinTweenValue, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = target})
	activeCoinTween:Play()
end

local function indexOf(list, value)
	for i, item in ipairs(list or {}) do
		if item == value then return i end
	end
	return 0
end

local function updateLoadoutText()
	if primaryText then
		primaryText.Text = string.format("Primary: %s", tostring(loadoutState.EquippedPrimary))
	end
	if secondaryText then
		secondaryText.Text = string.format("Secondary: %s", tostring(loadoutState.EquippedSecondary))
	end
	if meleeText then
		meleeText.Text = string.format("Melee: %s", tostring(loadoutState.EquippedMelee))
	end
end

local function getBoolSetting(attrName, defaultValue)
	local value = player:GetAttribute(attrName)
	if value == nil then
		player:SetAttribute(attrName, defaultValue)
		return defaultValue
	end
	return value == true
end

local function getNumberSetting(attrName, defaultValue, minValue, maxValue)
	local value = tonumber(player:GetAttribute(attrName))
	if value == nil then
		value = defaultValue
	end
	value = math.clamp(value, minValue, maxValue)
	player:SetAttribute(attrName, value)
	return value
end

local function applyMouseSensitivity()
	mouseSensitivity = getNumberSetting("MouseSensitivity", 1, 0.2, 2.5)
	pcall(function()
		UserInputService.MouseDeltaSensitivity = mouseSensitivity
	end)
end

local function ensureToggleSettingRow(rowName, labelText, layoutOrder, attrName, defaultValue)
	if not settingsList then return end
	local row = settingsList:FindFirstChild(rowName)
	if not row then
		row = Instance.new("Frame")
		row.Name = rowName
		row.LayoutOrder = layoutOrder
		row.Size = UDim2.new(1, 0, 0, 46)
		row.BackgroundColor3 = Color3.fromRGB(45, 38, 63)
		row.BorderSizePixel = 0
		row.Parent = settingsList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.05, 0)
		label.Size = UDim2.fromScale(0.55, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamSemibold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(243, 233, 255)
		label.Text = labelText
		label.Parent = row

		local toggle = Instance.new("TextButton")
		toggle.Name = "Toggle"
		toggle.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Position = UDim2.fromScale(0.95, 0.5)
		toggle.Size = UDim2.fromScale(0.28, 0.72)
		toggle.BackgroundColor3 = Color3.fromRGB(126, 103, 172)
		toggle.BorderSizePixel = 0
		toggle.Font = Enum.Font.GothamBold
		toggle.TextScaled = true
		toggle.TextColor3 = Color3.fromRGB(253, 245, 255)
		toggle.Parent = row

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 10)
		toggleCorner.Parent = toggle

		toggle.Activated:Connect(function()
			local nextValue = not getBoolSetting(attrName, defaultValue)
			player:SetAttribute(attrName, nextValue)
			if attrName == "ShowDamageNumbers" then
				damageNumbersEnabled = nextValue
			elseif attrName == "ShowKillFeed" then
				showKillFeedEnabled = nextValue
				if not nextValue then
					for i = #killFeedEntries, 1, -1 do
						local entry = killFeedEntries[i]
						if entry and entry.Parent then entry:Destroy() end
						killFeedEntries[i] = nil
					end
				end
			end
			toggle.Text = nextValue and "ON" or "OFF"
			toggle.BackgroundColor3 = nextValue and Color3.fromRGB(160, 128, 218) or Color3.fromRGB(126, 103, 172)
		end)
	end

	local enabled = getBoolSetting(attrName, defaultValue)
	if attrName == "ShowDamageNumbers" then
		damageNumbersEnabled = enabled
	elseif attrName == "ShowKillFeed" then
		showKillFeedEnabled = enabled
	end

	local toggle = row:FindFirstChild("Toggle")
	if toggle and toggle:IsA("TextButton") then
		toggle.Text = enabled and "ON" or "OFF"
		toggle.BackgroundColor3 = enabled and Color3.fromRGB(160, 128, 218) or Color3.fromRGB(126, 103, 172)
	end
end

local function ensureSensitivitySettingRow()
	if not settingsList then return end
	local row = settingsList:FindFirstChild("SensitivityRow")
	if not row then
		row = Instance.new("Frame")
		row.Name = "SensitivityRow"
		row.LayoutOrder = 95
		row.Size = UDim2.new(1, 0, 0, 46)
		row.BackgroundColor3 = Color3.fromRGB(45, 38, 63)
		row.BorderSizePixel = 0
		row.Parent = settingsList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.05, 0)
		label.Size = UDim2.fromScale(0.42, 1)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Font = Enum.Font.GothamSemibold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(243, 233, 255)
		label.Text = "Mouse Sensitivity"
		label.Parent = row

		local minus = Instance.new("TextButton")
		minus.Name = "Minus"
		minus.AnchorPoint = Vector2.new(1, 0.5)
		minus.Position = UDim2.fromScale(0.64, 0.5)
		minus.Size = UDim2.fromScale(0.14, 0.72)
		minus.BackgroundColor3 = Color3.fromRGB(126, 103, 172)
		minus.BorderSizePixel = 0
		minus.Font = Enum.Font.GothamBold
		minus.TextScaled = true
		minus.TextColor3 = Color3.fromRGB(253, 245, 255)
		minus.Text = "-"
		minus.Parent = row
		local minusCorner = Instance.new("UICorner")
		minusCorner.CornerRadius = UDim.new(0, 10)
		minusCorner.Parent = minus

		local value = Instance.new("TextLabel")
		value.Name = "Value"
		value.AnchorPoint = Vector2.new(1, 0.5)
		value.Position = UDim2.fromScale(0.82, 0.5)
		value.Size = UDim2.fromScale(0.18, 0.72)
		value.BackgroundTransparency = 1
		value.Font = Enum.Font.GothamBold
		value.TextScaled = true
		value.TextColor3 = Color3.fromRGB(253, 245, 255)
		value.Text = "1.00x"
		value.Parent = row

		local plus = Instance.new("TextButton")
		plus.Name = "Plus"
		plus.AnchorPoint = Vector2.new(1, 0.5)
		plus.Position = UDim2.fromScale(0.96, 0.5)
		plus.Size = UDim2.fromScale(0.14, 0.72)
		plus.BackgroundColor3 = Color3.fromRGB(126, 103, 172)
		plus.BorderSizePixel = 0
		plus.Font = Enum.Font.GothamBold
		plus.TextScaled = true
		plus.TextColor3 = Color3.fromRGB(253, 245, 255)
		plus.Text = "+"
		plus.Parent = row
		local plusCorner = Instance.new("UICorner")
		plusCorner.CornerRadius = UDim.new(0, 10)
		plusCorner.Parent = plus

		local function stepSensitivity(delta)
			local current = getNumberSetting("MouseSensitivity", 1, 0.2, 2.5)
			local nextValue = math.clamp(current + delta, 0.2, 2.5)
			nextValue = math.floor(nextValue * 100 + 0.5) / 100
			player:SetAttribute("MouseSensitivity", nextValue)
			applyMouseSensitivity()
			value.Text = string.format("%.2fx", mouseSensitivity)
		end

		minus.Activated:Connect(function()
			stepSensitivity(-0.05)
		end)
		plus.Activated:Connect(function()
			stepSensitivity(0.05)
		end)
	end

	applyMouseSensitivity()
	local valueLabel = row:FindFirstChild("Value")
	if valueLabel and valueLabel:IsA("TextLabel") then
		valueLabel.Text = string.format("%.2fx", mouseSensitivity)
	end
end

local function ensureSettingsRows()
	ensureToggleSettingRow("DamageNumbersRow", "Show Damage Numbers", 90, "ShowDamageNumbers", false)
	ensureToggleSettingRow("HitmarkerRow", "Show Hitmarkers", 91, "ShowHitmarkers", true)
	ensureToggleSettingRow("HitSoundsRow", "Play Hit Sounds", 92, "PlayHitSounds", true)
	ensureToggleSettingRow("LowHealthFxRow", "Low Health Effects", 93, "LowHealthEffects", true)
	ensureToggleSettingRow("KillFeedRow", "Show Kill Feed", 94, "ShowKillFeed", true)
	ensureSensitivitySettingRow()
end

local function refreshShopCards()
	for weaponName, refs in pairs(shopCards) do
		local item = shopData[weaponName]
		local owned = listHas(loadoutState.OwnedWeapons.Primary, weaponName)
			or listHas(loadoutState.OwnedWeapons.Secondary, weaponName)
			or listHas(loadoutState.OwnedWeapons.Melee, weaponName)
		local equipped = (item.Category == "Primary" and loadoutState.EquippedPrimary == weaponName)
			or (item.Category == "Secondary" and loadoutState.EquippedSecondary == weaponName)
			or (item.Category == "Melee" and loadoutState.EquippedMelee == weaponName)
		local pending = purchasePending[weaponName] == true

		if refs.State then
			if pending then
				refs.State.Text = "Processing..."
			elseif equipped then
				refs.State.Text = "Equipped"
			elseif owned then
				refs.State.Text = "Owned"
			else
				refs.State.Text = string.format("Price: %s", formatCoins(item.Price))
			end
		end

		if refs.Button then
			if pending then
				refs.Button.Text = "..."
				refs.Button.Active = false
				refs.Button.AutoButtonColor = false
			elseif owned then
				refs.Button.Text = equipped and "Equipped" or "Owned"
				refs.Button.Active = false
				refs.Button.AutoButtonColor = false
			else
				refs.Button.Text = item.Price > 0 and ("Buy " .. formatCoins(item.Price)) or "Free"
				refs.Button.Active = true
				refs.Button.AutoButtonColor = true
			end
		end
	end
end

local function buildShopCards()
	if not itemGrid then return end
	itemGrid.Active = false
	itemGrid.ScrollingEnabled = false
	itemGrid.ScrollingDirection = Enum.ScrollingDirection.Y
	itemGrid.ScrollBarThickness = 0
	itemGrid.AutomaticCanvasSize = Enum.AutomaticSize.None
	itemGrid.CanvasSize = UDim2.fromOffset(0, 0)
	itemGrid.ClipsDescendants = true

	local shopScale = shopMenu:FindFirstChildOfClass("UIScale")
	if not shopScale then
		shopScale = Instance.new("UIScale")
		shopScale.Parent = shopMenu
	end
	shopScale.Scale = 1

	for k in pairs(shopCards) do
		shopCards[k] = nil
	end

	local gridLayouts = {}
	for _, child in ipairs(itemGrid:GetChildren()) do
		if child:IsA("Frame") and string.sub(child.Name, 1, 9) == "ShopCard_" then
			child:Destroy()
		elseif child:IsA("UIGridLayout") then
			table.insert(gridLayouts, child)
		end
	end

	local gridLayout = gridLayouts[1]
	if not gridLayout then
		gridLayout = Instance.new("UIGridLayout")
		gridLayout.Parent = itemGrid
	else
		for i = 2, #gridLayouts do
			gridLayouts[i]:Destroy()
		end
	end
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local names = {}
	for weaponName in pairs(shopData) do
		table.insert(names, weaponName)
	end
	table.sort(names)

	local columns = math.max(1, math.min(4, #names > 0 and #names or 1))
	local rows = math.max(1, math.ceil((#names > 0 and #names or 1) / columns))
	local paddingX = 0.018
	local paddingY = 0.02
	local cellWidth = (1 - ((columns - 1) * paddingX)) / columns
	local cellHeight = (1 - ((rows - 1) * paddingY)) / rows
	gridLayout.CellPadding = UDim2.fromScale(paddingX, paddingY)
	gridLayout.CellSize = UDim2.fromScale(cellWidth, cellHeight)
	gridLayout.FillDirectionMaxCells = columns

	for i, weaponName in ipairs(names) do
		local item = shopData[weaponName]
		local card = Instance.new("Frame")
		card.Name = "ShopCard_" .. weaponName
		card.LayoutOrder = i
		card.BackgroundColor3 = Color3.fromRGB(42, 36, 58)
		card.BorderSizePixel = 0
		card.Parent = itemGrid

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(218, 194, 245)
		stroke.Transparency = 0.25
		stroke.Thickness = 1.2
		stroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.fromScale(0.06, 0.07)
		nameLabel.Size = UDim2.fromScale(0.88, 0.28)
		nameLabel.Text = weaponName
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.TextColor3 = Color3.fromRGB(244, 236, 255)
		nameLabel.Parent = card

		local stateLabel = Instance.new("TextLabel")
		stateLabel.Name = "State"
		stateLabel.BackgroundTransparency = 1
		stateLabel.Position = UDim2.fromScale(0.06, 0.36)
		stateLabel.Size = UDim2.fromScale(0.88, 0.2)
		stateLabel.Text = item.Category
		stateLabel.Font = Enum.Font.Gotham
		stateLabel.TextScaled = true
		stateLabel.TextColor3 = Color3.fromRGB(220, 204, 245)
		stateLabel.Parent = card

		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.AnchorPoint = Vector2.new(0.5, 0.5)
		buyButton.Position = UDim2.fromScale(0.5, 0.77)
		buyButton.Size = UDim2.fromScale(0.84, 0.30)
		buyButton.BackgroundColor3 = Color3.fromRGB(142, 118, 189)
		buyButton.TextColor3 = Color3.fromRGB(255, 245, 255)
		buyButton.Font = Enum.Font.GothamSemibold
		buyButton.TextScaled = true
		buyButton.BorderSizePixel = 0
		buyButton.Parent = card

		local buyCorner = Instance.new("UICorner")
		buyCorner.CornerRadius = UDim.new(0, 10)
		buyCorner.Parent = buyButton

		buyButton.Activated:Connect(function()
			if currentState ~= "Lobby" then return end
			if purchasePending[weaponName] then return end
			purchasePending[weaponName] = true
			refreshShopCards()
			uiRemotes.BuyWeapon:FireServer(weaponName)
		end)

		shopCards[weaponName] = {
			Card = card,
			State = stateLabel,
			Button = buyButton,
		}
	end

	refreshShopCards()
end

local function relayoutKillFeedEntries()
	for index, entry in ipairs(killFeedEntries) do
		if entry and entry.Parent then
			local target = UDim2.new(0, 0, 0, (index - 1) * 36)
			TweenService:Create(entry, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = target}):Play()
		end
	end
end

local function weaponIconText(payload)
	if payload.IsMelee then return "MEL" end
	local weapon = tostring(payload.Weapon or "")
	if weapon == "Sniper" then return "SNP" end
	if weapon == "Shotgun" then return "SG" end
	if weapon == "Pistol" then return "PST" end
	if weapon == "Rifle" then return "RFL" end
	return "GUN"
end

local function formatKillFeedText(payload)
	return string.format("%s  ->  %s", tostring(payload.KillerName or "Player"), tostring(payload.VictimName or "Player"))
end

local function pushKillFeed(payload, color)
	if not killFeedFrame then return end
	showKillFeedEnabled = getBoolSetting("ShowKillFeed", true)
	if not showKillFeedEnabled then return end
	local legacyLayout = killFeedFrame:FindFirstChildOfClass("UIListLayout")
	if legacyLayout then legacyLayout:Destroy() end

	if typeof(payload) ~= "table" then
		payload = {
			KillerName = tostring(payload),
			VictimName = "Player",
			Weapon = "",
			Headshot = false,
			IsMelee = false,
		}
	end

	local entry = Instance.new("Frame")
	entry.Name = "KillFeedEntry"
	entry.AnchorPoint = Vector2.new(0, 0)
	entry.Position = UDim2.new(1.08, 0, 0, 0)
	entry.Size = UDim2.new(1, 0, 0, 32)
	entry.BackgroundColor3 = Color3.fromRGB(27, 22, 44)
	entry.BackgroundTransparency = 0.32
	entry.BorderSizePixel = 0
	entry.Parent = killFeedFrame
	entry.ZIndex = 7

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 8)
	entryCorner.Parent = entry

	local entryStroke = Instance.new("UIStroke")
	entryStroke.Color = color or Color3.fromRGB(236, 220, 255)
	entryStroke.Thickness = 1.2
	entryStroke.Transparency = 0.3
	entryStroke.Parent = entry

	local icon = Instance.new("TextLabel")
	icon.Name = "WeaponIcon"
	icon.BackgroundColor3 = payload.IsMelee and Color3.fromRGB(255, 199, 226) or Color3.fromRGB(208, 181, 255)
	icon.BackgroundTransparency = 0.1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(0.03, 0.5)
	icon.Size = UDim2.fromScale(0.16, 0.7)
	icon.Font = Enum.Font.GothamBold
	icon.TextScaled = true
	icon.TextColor3 = Color3.fromRGB(36, 28, 52)
	icon.Text = weaponIconText(payload)
	icon.BorderSizePixel = 0
	icon.Parent = entry
	icon.ZIndex = 8
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 7)
	iconCorner.Parent = icon

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.22, 0)
	label.Size = UDim2.fromScale(0.62, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamSemibold
	label.TextScaled = true
	label.Text = formatKillFeedText(payload)
	label.TextColor3 = color or Color3.fromRGB(255, 240, 255)
	label.Parent = entry
	label.ZIndex = 8

	if payload.Headshot then
		local hs = Instance.new("TextLabel")
		hs.Name = "HeadshotIcon"
		hs.BackgroundColor3 = Color3.fromRGB(255, 190, 238)
		hs.BackgroundTransparency = 0.08
		hs.AnchorPoint = Vector2.new(1, 0.5)
		hs.Position = UDim2.fromScale(0.97, 0.5)
		hs.Size = UDim2.fromScale(0.12, 0.7)
		hs.Font = Enum.Font.GothamBold
		hs.TextScaled = true
		hs.TextColor3 = Color3.fromRGB(56, 38, 78)
		hs.Text = "HS"
		hs.BorderSizePixel = 0
		hs.Parent = entry
		hs.ZIndex = 8
		local hsCorner = Instance.new("UICorner")
		hsCorner.CornerRadius = UDim.new(0, 7)
		hsCorner.Parent = hs
	end

	table.insert(killFeedEntries, 1, entry)
	while #killFeedEntries > MAX_KILL_FEED_ENTRIES do
		local oldest = table.remove(killFeedEntries)
		if oldest and oldest.Parent then oldest:Destroy() end
	end
	relayoutKillFeedEntries()

	TweenService:Create(entry, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, entry.Position.Y.Offset)}):Play()

	task.delay(KILL_FEED_ENTRY_LIFETIME, function()
		if not entry or not entry.Parent then return end
		TweenService:Create(entry, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			Position = UDim2.new(1.08, 0, 0, entry.Position.Y.Offset),
		}):Play()
		if label and label.Parent then
			TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
		end
		task.delay(0.22, function()
			for i, e in ipairs(killFeedEntries) do
				if e == entry then
					table.remove(killFeedEntries, i)
					break
				end
			end
			if entry and entry.Parent then entry:Destroy() end
			relayoutKillFeedEntries()
		end)
	end)
end

local function ensureLoadoutSelectorUI()
	if not loadoutMenu then return end

	if slots then
		slots.Position = UDim2.fromScale(0.04, 0.2)
		slots.Size = UDim2.fromScale(0.54, 0.72)
		slots.BackgroundTransparency = 1
		slots.ZIndex = 8
		slots.ClipsDescendants = true
		for _, child in ipairs(slots:GetChildren()) do
			if child:IsA("Frame") then
				child.ZIndex = 9
				for _, grandChild in ipairs(child:GetDescendants()) do
					if grandChild:IsA("GuiObject") then
						grandChild.ZIndex = math.max(grandChild.ZIndex, 10)
					end
				end
			end
		end
	end

	loadoutSelectorPanel = loadoutMenu:FindFirstChild("SelectorPanel")
	if not loadoutSelectorPanel then
		loadoutSelectorPanel = Instance.new("Frame")
		loadoutSelectorPanel.Name = "SelectorPanel"
		loadoutSelectorPanel.Parent = loadoutMenu

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = loadoutSelectorPanel

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(214, 192, 247)
		stroke.Transparency = 0.25
		stroke.Thickness = 1.2
		stroke.Parent = loadoutSelectorPanel
	end

	loadoutSelectorPanel.AnchorPoint = Vector2.new(1, 0.5)
	loadoutSelectorPanel.Position = UDim2.fromScale(0.96, 0.56)
	loadoutSelectorPanel.Size = UDim2.fromScale(0.36, 0.72)
	loadoutSelectorPanel.BackgroundColor3 = Color3.fromRGB(34, 28, 49)
	loadoutSelectorPanel.BackgroundTransparency = 0.08
	loadoutSelectorPanel.BorderSizePixel = 0
	loadoutSelectorPanel.Visible = false
	loadoutSelectorPanel.ZIndex = 25

	loadoutSelectorTitle = loadoutSelectorPanel:FindFirstChild("Title")
	if not loadoutSelectorTitle then
		loadoutSelectorTitle = Instance.new("TextLabel")
		loadoutSelectorTitle.Name = "Title"
		loadoutSelectorTitle.BackgroundTransparency = 1
		loadoutSelectorTitle.Position = UDim2.fromScale(0.08, 0.04)
		loadoutSelectorTitle.Size = UDim2.fromScale(0.7, 0.12)
		loadoutSelectorTitle.Font = Enum.Font.GothamBold
		loadoutSelectorTitle.TextScaled = true
		loadoutSelectorTitle.TextColor3 = Color3.fromRGB(245, 235, 255)
		loadoutSelectorTitle.TextXAlignment = Enum.TextXAlignment.Left
		loadoutSelectorTitle.Parent = loadoutSelectorPanel
	end
	loadoutSelectorTitle.ZIndex = 26

	local closeButton = loadoutSelectorPanel:FindFirstChild("CloseButton")
	if not closeButton then
		closeButton = Instance.new("TextButton")
		closeButton.Name = "CloseButton"
		closeButton.AnchorPoint = Vector2.new(1, 0)
		closeButton.Position = UDim2.fromScale(0.96, 0.04)
		closeButton.Size = UDim2.fromScale(0.16, 0.12)
		closeButton.BackgroundColor3 = Color3.fromRGB(111, 88, 151)
		closeButton.BackgroundTransparency = 0.12
		closeButton.BorderSizePixel = 0
		closeButton.Font = Enum.Font.GothamBold
		closeButton.TextScaled = true
		closeButton.TextColor3 = Color3.fromRGB(252, 245, 255)
		closeButton.Text = "X"
		closeButton.Parent = loadoutSelectorPanel
		local cc = Instance.new("UICorner")
		cc.CornerRadius = UDim.new(0, 10)
		cc.Parent = closeButton
		closeButton.Activated:Connect(function()
			if loadoutSelectorPanel then
				loadoutSelectorPanel.Visible = false
				loadoutSelectorSlot = nil
			end
		end)
	end
	closeButton.ZIndex = 27

	loadoutSelectorList = loadoutSelectorPanel:FindFirstChild("List")
	if not loadoutSelectorList then
		loadoutSelectorList = Instance.new("Frame")
		loadoutSelectorList.Name = "List"
		loadoutSelectorList.BackgroundTransparency = 1
		loadoutSelectorList.Position = UDim2.fromScale(0.07, 0.2)
		loadoutSelectorList.Size = UDim2.fromScale(0.86, 0.74)
		loadoutSelectorList.Parent = loadoutSelectorPanel

		local listLayout = Instance.new("UIListLayout")
		listLayout.Name = "Layout"
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.Padding = UDim.new(0.02, 0)
		listLayout.Parent = loadoutSelectorList
	end
	loadoutSelectorList.ZIndex = 26
end

local function populateLoadoutSelector(slotName)
	ensureLoadoutSelectorUI()
	if not loadoutSelectorPanel or not loadoutSelectorList or not loadoutSelectorTitle then return end

	loadoutSelectorSlot = slotName
	loadoutSelectorTitle.Text = string.format("Select %s", slotName)

	for _, child in ipairs(loadoutSelectorList:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local options = loadoutState.OwnedWeapons[slotName] or {}
	local equippedKey = "Equipped" .. slotName

	if #options == 0 then
		local empty = Instance.new("TextLabel")
		empty.Name = "Empty"
		empty.LayoutOrder = 1
		empty.Size = UDim2.fromScale(1, 0.16)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamSemibold
		empty.TextScaled = true
		empty.TextColor3 = Color3.fromRGB(229, 212, 249)
		empty.Text = "No weapons owned"
		empty.ZIndex = 27
		empty.Parent = loadoutSelectorList
		return
	end

	local buttonHeight = math.clamp(0.9 / #options, 0.12, 0.22)
	for i, weaponName in ipairs(options) do
		local option = Instance.new("TextButton")
		option.Name = "Option_" .. weaponName
		option.LayoutOrder = i
		option.Size = UDim2.fromScale(1, buttonHeight)
		option.BackgroundColor3 = equipped and Color3.fromRGB(142, 112, 190) or Color3.fromRGB(71, 56, 101)
		option.BackgroundTransparency = 0.12
		option.BorderSizePixel = 0
		option.Font = Enum.Font.GothamSemibold
		option.TextScaled = true
		option.TextColor3 = Color3.fromRGB(251, 244, 255)
		option.Text = equipped and (weaponName .. "   EQUIPPED") or weaponName
		option.Active = true
		option.Selectable = true
		option.ZIndex = 27
		option.Parent = loadoutSelectorList

		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 10)
		optionCorner.Parent = option

		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 10)
		optionCorner.Parent = option

		option.Activated:Connect(function()
			if currentState ~= "Lobby" then return end
			uiRemotes.SetLoadout:FireServer(slotName, weaponName)
			loadoutSelectorPanel.Visible = false
			loadoutSelectorSlot = nil
		end)
	end
end

local function openLoadoutSelector(slotName)
	if currentState ~= "Lobby" then return end
	populateLoadoutSelector(slotName)
	if loadoutSelectorPanel then
		loadoutSelectorPanel.Visible = true
	end
end

local function cycleSlot(slotName)
	openLoadoutSelector(slotName)
end

local function wireButton(button, callback)
	if not button then return end
	if button:IsA("GuiButton") then
		button.Active = true
		button.Selectable = true
	end
	button.Activated:Connect(function(...)
		callback(...)
	end)
end

local function wireSlot(frame, slotName)
	if not frame then return end
	local click = frame:FindFirstChild("ClickArea")
	if not click then
		click = Instance.new("TextButton")
		click.Name = "ClickArea"
		click.BackgroundTransparency = 1
		click.Text = ""
		click.AutoButtonColor = false
		click.Size = UDim2.fromScale(1, 1)
		click.Position = UDim2.fromScale(0, 0)
		click.Parent = frame
	end
	click.Active = true
	click.Selectable = false
	click.ZIndex = math.max(click.ZIndex, 20)
	wireButton(click, function() cycleSlot(slotName) end)
end

local function refreshScoreboardActionButtons()
	if not scoreboardTeamButton or not scoreboardMainMenuButton then return end
	local showButtons = isMobileClient
	scoreboardTeamButton.Visible = showButtons
	scoreboardMainMenuButton.Visible = showButtons
end

local function applyScoreboardVisibility()
	if not scoreboardFrame then return end
	refreshScoreboardActionButtons()
	scoreboardFrame.Visible = (currentState == "Playing") and scoreboardOpen
end

local function getLocalTeam()
	local teamName = player:GetAttribute("AssignedTeam")
	if teamName == "Pink" or teamName == "Purple" then
		return teamName
	end
	return ""
end

local function teamRowColor(teamName)
	if teamName == "Pink" then
		return Color3.fromRGB(255, 199, 226)
	elseif teamName == "Purple" then
		return Color3.fromRGB(214, 194, 255)
	end
	return Color3.fromRGB(235, 227, 247)
end

local function applyScoreboardTheme()
	if not scoreboardFrame then return end
	local teamName = getLocalTeam()
	local accent = teamRowColor(teamName)
	local bg = Color3.fromRGB(26, 20, 40)
	if teamName == "Pink" then
		bg = Color3.fromRGB(48, 30, 44)
	elseif teamName == "Purple" then
		bg = Color3.fromRGB(36, 29, 55)
	end
	scoreboardFrame.BackgroundColor3 = bg
	local stroke = scoreboardFrame:FindFirstChildOfClass("UIStroke")
	if stroke then stroke.Color = accent end
	local title = scoreboardFrame:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.TextColor3 = accent
	end
end

local function normalizeRows(payload)
	if typeof(payload.Rows) == "table" and #payload.Rows > 0 then
		return payload.Rows
	end
	local rows = {}
	local statsById = payload.PlayerStats
	if typeof(statsById) ~= "table" then
		return rows
	end
	for _, p in ipairs(Players:GetPlayers()) do
		local stats = statsById[p.UserId] or {}
		local kills = tonumber(stats.Kills) or 0
		local deaths = tonumber(stats.Deaths) or 0
		local kd = kills / math.max(1, deaths)
		local assists = tonumber(stats.Assists) or tonumber(stats.RoundAssists) or 0
		rows[#rows + 1] = {
			UserId = p.UserId,
			Name = p.DisplayName ~= "" and p.DisplayName or p.Name,
			Team = p:GetAttribute("AssignedTeam") or "",
			Kills = kills,
			Deaths = deaths,
			Assists = assists,
			KD = kd,
			Score = (kills * 100) + (assists * 30) - (deaths * 10),
		}
	end
	table.sort(rows, function(a, b)
		if a.Score ~= b.Score then return a.Score > b.Score end
		return (a.Kills or 0) > (b.Kills or 0)
	end)
	return rows
end

local function rebuildScoreboard(rows)
	ensureScoreboard()
	for _, child in ipairs(scoreboardRows:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local localTeam = getLocalTeam()
	for i, row in ipairs(rows) do
		local line = Instance.new("TextLabel")
		line.Name = "Row" .. i
		line.LayoutOrder = i
		line.Size = UDim2.fromScale(1, 0.09)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.Code
		line.TextScaled = true
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextColor3 = teamRowColor(tostring(row.Team or ""))
		if tostring(row.Team or "") == localTeam then
			line.BackgroundColor3 = teamRowColor(localTeam)
			line.BackgroundTransparency = 0.88
		end
		if tonumber(row.UserId) == player.UserId then
			line.BackgroundColor3 = teamRowColor(localTeam)
			line.BackgroundTransparency = 0.72
		end
		line.Text = string.format(
			"%s | %s | %d | %d | %d | %.2f | %d",
			string.sub(tostring(row.Name or "Player"), 1, 16),
			string.sub(tostring(row.Team or "-"), 1, 6),
			tonumber(row.Kills) or 0,
			tonumber(row.Deaths) or 0,
			tonumber(row.Assists) or 0,
			tonumber(row.KD) or 0,
			tonumber(row.Score) or 0
		)
		line.Parent = scoreboardRows
	end
	applyScoreboardTheme()
end

local function applyState(state)
	currentState = state
	loadingScreen.Enabled = (state == "Loading")

	local menuOverlayInPlaying = (state == "Playing") and (player:GetAttribute("IsInMenu") == true)
	if state == "Lobby" or menuOverlayInPlaying then
		mainUI.Enabled = true
		showMenu(mainMenu)
	elseif state == "TeamSelect" or state == "MapVote" or state == "Countdown" or state == "Playing" or state == "Ending" then
		mainUI.Enabled = false
	else
		mainUI.Enabled = false
	end

	hud.Enabled = (state == "Playing")
	showKillFeedEnabled = getBoolSetting("ShowKillFeed", true)
	if killFeedFrame then
		killFeedFrame.Visible = showKillFeedEnabled and (state == "Playing")
	end
	setMobileEnabled(state == "Playing")
	local manualSwitchMenu = (state == "Playing") and (player:GetAttribute("TeamSwitchPending") == true)
	teamSelectGui.Enabled = (state == "TeamSelect") or manualSwitchMenu
	mapVoteGui.Enabled = (state == "MapVote")
	countdownGui.Enabled = (state == "Countdown" or state == "Ending")
	disableDefaultPlayerList()
	if state ~= "Playing" then
		respawnGui.Enabled = false
		scoreboardOpen = false
		if matchTimerLabel then
			matchTimerLabel.Text = "TIME 00:00"
			matchTimerLabel.TextColor3 = Color3.fromRGB(246, 236, 255)
		end
	end
	applyScoreboardTheme()
	applyScoreboardVisibility()
	if state == "Playing" and not teamSelectGui.Enabled and player:GetAttribute("IsInMenu") ~= true then
		setMouseMenuOverride(false)
	else
		forceMenuMouseUnlock()
	end
end

local function onPlayPressed()
	if currentState == "Lobby" then
		uiRemotes.PlayGame:FireServer()
		return
	end
	if currentState == "Playing" and player:GetAttribute("IsInMenu") == true then
		openTeamSelectMenuForSwitch()
	end
end

wireButton(playButton, onPlayPressed)
wireButton(loadoutButton, function()
	if currentState ~= "Lobby" then return end
	showMenu(loadoutMenu)
	ensureLoadoutSelectorUI()
	if loadoutSelectorPanel then
		loadoutSelectorPanel.Visible = false
		loadoutSelectorSlot = nil
	end
	uiRemotes.SetLoadout:FireServer("RequestSync", "")
end)
wireButton(shopButton, function()
	if currentState ~= "Lobby" then return end
	showMenu(shopMenu)
	if shopFeedback then shopFeedback.Text = "" end
	refreshShopCards()
end)
wireButton(settingsButton, function()
	if currentState == "Lobby" then
		ensureSettingsRows()
		showMenu(settingsMenu)
	end
end)
wireButton(serversButton, function() if currentState == "Lobby" then showMenu(serverBrowser) end end)

wireButton(tsPink, function()
	requestTeamSwitch("Pink")
end)
wireButton(tsPurple, function()
	requestTeamSwitch("Purple")
end)
wireButton(scoreboardTeamButton, function()
	if not canOpenTeamSwitchMenu() then return end
	scoreboardOpen = false
	applyScoreboardVisibility()
	openTeamSelectMenuForSwitch()
end)
wireButton(scoreboardMainMenuButton, function()
	scoreboardOpen = false
	applyScoreboardVisibility()
	requestMainMenuReturn()
end)
wireButton(tsClose, function()
	closeTeamSelectMenuIfManual()
end)

for _, page in ipairs({loadoutMenu, shopMenu, settingsMenu, serverBrowser}) do
	local exitButton = page:FindFirstChild("ExitButton")
	wireButton(exitButton, function() if currentState == "Lobby" then showMenu(mainMenu) end end)
end

wireSlot(primarySlot, "Primary")
wireSlot(secondarySlot, "Secondary")
wireSlot(meleeSlot, "Melee")

uiRemotes.LoadoutSync.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if typeof(payload.OwnedWeapons) == "table" then
		loadoutState.OwnedWeapons.Primary = payload.OwnedWeapons.Primary or loadoutState.OwnedWeapons.Primary
		loadoutState.OwnedWeapons.Secondary = payload.OwnedWeapons.Secondary or loadoutState.OwnedWeapons.Secondary
		loadoutState.OwnedWeapons.Melee = payload.OwnedWeapons.Melee or loadoutState.OwnedWeapons.Melee
	end
	if typeof(payload.EquippedPrimary) == "string" then loadoutState.EquippedPrimary = payload.EquippedPrimary end
	if typeof(payload.EquippedSecondary) == "string" then loadoutState.EquippedSecondary = payload.EquippedSecondary end
	if typeof(payload.EquippedMelee) == "string" then loadoutState.EquippedMelee = payload.EquippedMelee end
	updateLoadoutText()
	if loadoutSelectorPanel and loadoutSelectorPanel.Visible and loadoutSelectorSlot then
		populateLoadoutSelector(loadoutSelectorSlot)
	end
	refreshShopCards()
end)

uiRemotes.CurrencyUpdated.OnClientEvent:Connect(function(coins)
	animateCoins(tonumber(coins) or currentCoins)
	refreshShopCards()
end)

uiRemotes.ShopPurchaseResult.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then return end
	local weaponName = typeof(result.WeaponName) == "string" and result.WeaponName or ""
	if weaponName ~= "" then purchasePending[weaponName] = nil end
	if result.Coins ~= nil then animateCoins(tonumber(result.Coins) or currentCoins) end
	if shopFeedback then
		if result.Success then
			shopFeedback.Text = "Purchased " .. weaponName
			shopFeedback.TextColor3 = Color3.fromRGB(188, 255, 214)
		else
			if result.Code == "InsufficientFunds" then
				shopFeedback.Text = "Not enough coins"
			elseif result.Code == "AlreadyOwned" then
				shopFeedback.Text = "Already owned"
			elseif result.Code == "TooFast" then
				shopFeedback.Text = "Slow down"
			else
				shopFeedback.Text = "Purchase failed"
			end
			shopFeedback.TextColor3 = Color3.fromRGB(255, 200, 214)
		end
	end
	uiRemotes.SetLoadout:FireServer("RequestSync", "")
	refreshShopCards()
end)


mapVoteStart.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if not shouldShowMapVoteUI() then return end
	if currentState ~= "MapVote" then applyState("MapVote") end
	refreshMapVoteButtons(payload)
	updateVoteCounts(payload)
	local n = tonumber(payload.Duration) or tonumber(payload.TimeRemaining) or 15
	for i = n, 1, -1 do
		if currentState ~= "MapVote" then break end
		if not shouldShowMapVoteUI() then break end
		if mvTimer then mvTimer.Text = string.format("Map vote: %ds", i) end
		task.wait(1)
	end
end)

mapVoteUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if not shouldShowMapVoteUI() then return end
	updateVoteCounts(payload)
end)

assistAwarded.OnClientEvent:Connect(function(victimName)
	if typeof(victimName) ~= "string" then return end
	if shopFeedback and (currentState == "Lobby" or currentState == "TeamSelect") then
		shopFeedback.Text = "Assist on " .. victimName
		shopFeedback.TextColor3 = Color3.fromRGB(210, 196, 255)
	end
end)
matchEvents.TeamSelectStart.OnClientEvent:Connect(function(seconds)
	if currentState ~= "TeamSelect" then applyState("TeamSelect") end
	local n = tonumber(seconds) or 10
	for i = n, 1, -1 do
		if currentState ~= "TeamSelect" then break end
		if tsTimer then tsTimer.Text = string.format("Choose Team (%ds)", i) end
		task.wait(1)
	end
end)

matchEvents.TeamCounts.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if tsPinkCount then tsPinkCount.Text = string.format("%d Players", tonumber(payload.Pink) or 0) end
	if tsPurpleCount then tsPurpleCount.Text = string.format("%d Players", tonumber(payload.Purple) or 0) end
	if tsYourTeam then tsYourTeam.Text = "Team: " .. tostring(payload.YourTeam or "Auto") end
	local cooldown = math.max(0, math.floor(tonumber(payload.SwitchCooldown) or 0))
	if cooldown > 0 and tsTimer and currentState ~= "TeamSelect" then
		tsTimer.Text = string.format("Switch available in %ds", cooldown)
	elseif tsTimer and currentState ~= "TeamSelect" and teamSelectGui.Enabled then
		tsTimer.Text = "Switch Team"
	end
	applyScoreboardTheme()
end)

matchEvents.CountdownStart.OnClientEvent:Connect(function(seconds)
	if currentState ~= "Countdown" then applyState("Countdown") end
	local n = tonumber(seconds) or 5
	for i = n, 1, -1 do
		if currentState ~= "Countdown" then break end
		if cdLabel then cdLabel.Text = "Match Loading in " .. i end
		task.wait(1)
	end
	if currentState == "Countdown" and cdLabel then
		cdLabel.Text = "Deploying..."
	end
end)

matchEvents.RespawnStart.OnClientEvent:Connect(function(seconds)
	if currentState ~= "Playing" then return end
	local n = tonumber(seconds) or 5
	respawnGui.Enabled = true
	for i = n, 1, -1 do
		if currentState ~= "Playing" then break end
		if rsLabel then rsLabel.Text = "Respawning in " .. i end
		task.wait(1)
	end
	respawnGui.Enabled = false
end)

matchEvents.ScoreUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	local ts = payload.TeamScores or {}
	local target = tonumber(payload.TargetKills) or 0
	if scoreLabel then
		if target > 0 then
			scoreLabel.Text = string.format("Pink %d | %d Purple  (to %d)", tonumber(ts.Pink) or 0, tonumber(ts.Purple) or 0, target)
		else
			scoreLabel.Text = string.format("Pink %d | %d Purple", tonumber(ts.Pink) or 0, tonumber(ts.Purple) or 0)
		end
	end
	rebuildScoreboard(normalizeRows(payload))
end)

matchTimerUpdate.OnClientEvent:Connect(function(remaining)
	local seconds = math.max(0, math.floor(tonumber(remaining) or 0))
	if matchTimerLabel then
		matchTimerLabel.Text = "TIME " .. formatMatchTime(seconds)
		matchTimerLabel.TextColor3 = seconds <= 10 and Color3.fromRGB(255, 186, 208) or Color3.fromRGB(246, 236, 255)
	end
end)

matchEvents.RoundResult.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if not cdLabel then return end
	if payload.ToLobby then
		countdownGui.Enabled = false
		return
	end
	if currentState == "Ending" then
		local winner = payload.WinnerTeam or "No Team"
		cdLabel.Text = winner .. " wins!"
	end
end)

matchEvents.KillFeed.OnClientEvent:Connect(function(a, b, c)
	local payload
	if typeof(a) == "table" then
		payload = a
	else
		payload = {
			KillerName = tostring(a),
			VictimName = tostring(b),
			KillerTeam = tostring(c or ""),
			Weapon = "",
			Headshot = false,
			IsMelee = false,
		}
	end
	local color = Color3.fromRGB(255, 230, 250)
	if payload.KillerTeam == "Pink" then
		color = Color3.fromRGB(255, 180, 216)
	elseif payload.KillerTeam == "Purple" then
		color = Color3.fromRGB(206, 174, 255)
	end
	pushKillFeed(payload, color)
end)

matchEvents.StateChanged.OnClientEvent:Connect(function(state)
	applyState(state)
end)
gameStateValue:GetPropertyChangedSignal("Value"):Connect(function()
	applyState(gameStateValue.Value)
end)

for _, menuAttr in ipairs({"IsInMenu", "TeamSwitchPending"}) do
	player:GetAttributeChangedSignal(menuAttr):Connect(function()
		applyState(currentState)
		if player:GetAttribute(menuAttr) == true then
			forceMenuMouseUnlock()
		end
	end)
end

local function handleMenuHotkeys(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if input.KeyCode == Enum.KeyCode.M then
		if currentState ~= "Loading" then
			scoreboardOpen = false
			applyScoreboardVisibility()
			mainUI.Enabled = true
			showMenu(mainMenu)
			teamSelectGui.Enabled = false
			requestMainMenuReturn()
		end
		return Enum.ContextActionResult.Sink
	end
	if input.KeyCode == Enum.KeyCode.Period then
		if canOpenTeamSwitchMenu() then
			scoreboardOpen = false
			applyScoreboardVisibility()
			openTeamSelectMenuForSwitch()
		end
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end
ContextActionService:UnbindAction("MenuHotkeys")
ContextActionService:BindActionAtPriority(
	"MenuHotkeys",
	handleMenuHotkeys,
	false,
	3000,
	Enum.KeyCode.M,
	Enum.KeyCode.Period
)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		if currentState == "Playing" then
			scoreboardOpen = not scoreboardOpen
			applyScoreboardVisibility()
		end
	end
end)

clientAction.Event:Connect(function(action)
	if action == "ToggleMenu" and currentState == "Lobby" then
		mainUI.Enabled = true
		showMenu(mainMenu)
	elseif action == "ToggleScoreboard" and currentState == "Playing" then
		scoreboardOpen = not scoreboardOpen
		applyScoreboardVisibility()
	end
end)

player.CharacterAdded:Connect(function()
	if currentState ~= "Playing" then return end
	local inMenu = player:GetAttribute("IsInMenu") == true
	local switching = player:GetAttribute("TeamSwitchPending") == true
	if inMenu or switching then
		forceMenuMouseUnlock()
		return
	end
	if player:GetAttribute("ForceMenuMouseUnlock") == true then
		setMouseMenuOverride(false)
	end
end)

for _, attrName in ipairs({"ShowDamageNumbers", "ShowHitmarkers", "PlayHitSounds", "LowHealthEffects", "ShowKillFeed", "MouseSensitivity"}) do
	player:GetAttributeChangedSignal(attrName):Connect(function()
		if attrName == "MouseSensitivity" then
			applyMouseSensitivity()
		end
		if settingsMenu and settingsMenu.Visible then
			ensureSettingsRows()
		end
	end)
end

ensureSettingsRows()
buildShopCards()
updateLoadoutText()
applyCurrencyText(0)
uiRemotes.SetLoadout:FireServer("RequestSync", "")
applyState(gameStateValue.Value)
print("UIController local initialized")
