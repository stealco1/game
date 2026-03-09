local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainUI = playerGui:WaitForChild("MainUI", 10)
if not mainUI then warn("Navigation: MainUI not found"); return end

local pages = mainUI:WaitForChild("Pages", 10)
if not pages then warn("Navigation: Pages not found"); return end

local MainMenu = pages:WaitForChild("MainMenu", 10)
local LobbyMenu = pages:WaitForChild("LobbyMenu", 10)
local LoadoutMenu = pages:WaitForChild("LoadoutMenu", 10)
local ShopMenu = pages:WaitForChild("ShopMenu", 10)
local SettingsMenu = pages:WaitForChild("SettingsMenu", 10)
local ServerBrowser = pages:WaitForChild("ServerBrowser", 10)
if not (MainMenu and LobbyMenu and LoadoutMenu and ShopMenu and SettingsMenu and ServerBrowser) then
	warn("Navigation: one or more menu pages missing")
	return
end

local buttonContainer = MainMenu:WaitForChild("ButtonContainer", 10)
if not buttonContainer then
	warn("Navigation: ButtonContainer missing")
	return
end

if mainUI:GetAttribute("RequestedMatch") == nil then
	mainUI:SetAttribute("RequestedMatch", false)
end

local function closeAll()
	for _, m in ipairs(pages:GetChildren()) do
		if m:IsA("Frame") then m.Visible = false end
	end
end

local function openMenu(menu)
	closeAll()
	if menu then menu.Visible = true end
end

local function waitButton(name)
	local direct = MainMenu:FindFirstChild(name)
	if direct and direct:IsA("GuiButton") then return direct end
	local nested = buttonContainer:WaitForChild(name, 10)
	if nested and nested:IsA("GuiButton") then return nested end
	return nil
end

local function wire(button, fn)
	if not button then return end
	button.Active = true
	button.Selectable = true
	button.Visible = true
	button.MouseButton1Click:Connect(fn)
	button.Activated:Connect(fn)
end

wire(waitButton("LoadoutButton"), function() openMenu(LoadoutMenu) end)
wire(waitButton("ShopButton"), function() openMenu(ShopMenu) end)
wire(waitButton("SettingsButton"), function() openMenu(SettingsMenu) end)
wire(waitButton("ServersButton"), function() openMenu(ServerBrowser) end)

for _, menu in ipairs({LoadoutMenu, ShopMenu, SettingsMenu, ServerBrowser}) do
	local exitBtn = menu:FindFirstChild("ExitButton") or menu:WaitForChild("ExitButton", 10)
	wire(exitBtn, function() openMenu(MainMenu) end)
end

local playButton = waitButton("PlayButton")
wire(playButton, function()
	mainUI:SetAttribute("RequestedMatch", true)
	openMenu(LobbyMenu)
	local countdownLabel = LobbyMenu:FindFirstChild("CountdownLabel")
	if countdownLabel and countdownLabel:IsA("TextLabel") then
		countdownLabel.Text = "Starting match..."
	end
	if playButton then
		playButton.Active = false
		playButton.AutoButtonColor = false
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local uiRemotes = remotes and remotes:FindFirstChild("UIRemotes")
	local playGame = uiRemotes and uiRemotes:FindFirstChild("PlayGame")
	if playGame then playGame:FireServer() end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and not mainUI:GetAttribute("RequestedMatch") then
		closeAll()
		MainMenu.Visible = true
	end
end)

mainUI:GetAttributeChangedSignal("RequestedMatch"):Connect(function()
	if not mainUI:GetAttribute("RequestedMatch") and playButton then
		playButton.Active = true
		playButton.AutoButtonColor = true
	end
end)

closeAll()
MainMenu.Visible = true
mainUI.Enabled = true
print("Navigation initialized")
