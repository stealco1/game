local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local clientAction = shared:WaitForChild("ClientAction")
local gameState = shared:WaitForChild("GameState")

local MobileController = {
	IsOrientationValid = true,
}

local function ensureGui(name)
	local gui = playerGui:FindFirstChild(name)
	if gui then return gui end
	local template = StarterGui:FindFirstChild(name)
	if template and template:IsA("LayerCollector") then
		gui = template:Clone()
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
		return gui
	end
	return nil
end

local function ensureMobileControls()
	return ensureGui("MobileControls")
end

local function ensureRotateOverlay()
	return ensureGui("RotateDeviceOverlay")
end

local function createCircleButton(parent, name, text)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromScale(0.12, 0.12)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = 0.62
	button.BorderSizePixel = 0
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamSemibold
	button.TextColor3 = Color3.fromRGB(246, 238, 255)
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(228, 208, 252)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = button

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Name = "Aspect"
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.AspectRatio = 1
	aspect.DominantAxis = Enum.DominantAxis.Width
	aspect.Parent = button

	return button
end

local function ensureActionButton(mobile, name, text)
	local button = mobile:FindFirstChild(name)
	if button and button:IsA("TextButton") then
		return button
	end
	if button then
		button:Destroy()
	end
	return createCircleButton(mobile, name, text)
end

local function styleButton(button)
	if not button then return end
	button.BackgroundTransparency = 0.62
	button.AutoButtonColor = false
	button.TextTransparency = 0.08
	button.Active = true
	button.Visible = true
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0.2
	end
	button.MouseButton1Down:Connect(function()
		button.BackgroundTransparency = 0.46
	end)
	button.MouseButton1Up:Connect(function()
		button.BackgroundTransparency = 0.62
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundTransparency = 0.62
	end)
end

local function applyLayout()
	local mobile = ensureMobileControls()
	if not mobile then return end

	local fireButton = ensureActionButton(mobile, "FireButton", "FIRE")
	local reloadButton = ensureActionButton(mobile, "ReloadButton", "RLD")
	local switchButton = ensureActionButton(mobile, "SwitchButton", "SWP")
	local scoreboardButton = ensureActionButton(mobile, "ScoreboardButton", "TAB")
	local crouchButton = ensureActionButton(mobile, "CrouchButton", "CRH")
	local sprintButton = mobile:FindFirstChild("SprintButton")

	fireButton.Position = UDim2.fromScale(0.86, 0.70)
	reloadButton.Position = UDim2.fromScale(0.14, 0.74)
	switchButton.Position = UDim2.fromScale(0.14, 0.60)
	scoreboardButton.Position = UDim2.fromScale(0.14, 0.46)
	crouchButton.Position = UDim2.fromScale(0.30, 0.74)

	if sprintButton and sprintButton:IsA("GuiButton") then
		sprintButton.Visible = false
		sprintButton.Active = false
		sprintButton.AutoButtonColor = false
	end

	styleButton(fireButton)
	styleButton(reloadButton)
	styleButton(switchButton)
	styleButton(scoreboardButton)
	styleButton(crouchButton)
end

local function setScale()
	local mobile = ensureMobileControls()
	if not mobile then return end
	local scale = mobile:FindFirstChildOfClass("UIScale")
	if not scale then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local minDim = math.min(vp.X, vp.Y)
	scale.Scale = math.clamp(minDim / 900, 0.8, 1.15)
end

local function updateOrientationState()
	local cam = workspace.CurrentCamera
	if not cam then
		MobileController.IsOrientationValid = true
		return
	end
	local vp = cam.ViewportSize
	MobileController.IsOrientationValid = vp.X >= vp.Y
end

local function updateOverlayAndButtons()
	local mobile = ensureMobileControls()
	local overlay = ensureRotateOverlay()
	if not mobile then return end

	local isTouch = UserInputService.TouchEnabled
	local shouldBlock = isTouch and (not MobileController.IsOrientationValid)

	if overlay then
		overlay.Enabled = shouldBlock
	end

	for _, name in ipairs({"FireButton", "ReloadButton", "SwitchButton", "ScoreboardButton", "CrouchButton"}) do
		local btn = mobile:FindFirstChild(name)
		if btn and btn:IsA("GuiButton") then
			btn.Active = not shouldBlock
			btn.AutoButtonColor = not shouldBlock
		end
	end
end

local function setEnabledByPlatformAndState()
	local mobile = ensureMobileControls()
	if not mobile then return end
	local isTouch = UserInputService.TouchEnabled
	local inPlaying = gameState.Value == "Playing"
	mobile.Enabled = isTouch and inPlaying
	updateOverlayAndButtons()
end

local connected = false
local function connectButtons()
	if connected then return end
	local mobile = ensureMobileControls()
	if not mobile then return end
	connected = true
	applyLayout()

	local fireButton = mobile:FindFirstChild("FireButton")
	local reloadButton = mobile:FindFirstChild("ReloadButton")
	local switchButton = mobile:FindFirstChild("SwitchButton")
	local scoreButton = mobile:FindFirstChild("ScoreboardButton")
	local crouchButton = mobile:FindFirstChild("CrouchButton")

	if fireButton then
		fireButton.MouseButton1Down:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("FireDown")
		end)
		fireButton.MouseButton1Up:Connect(function()
			clientAction:Fire("FireUp")
		end)
		fireButton.TouchLongPress:Connect(function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				if not MobileController.IsOrientationValid then return end
				clientAction:Fire("FireDown")
			elseif inputState == Enum.UserInputState.End then
				clientAction:Fire("FireUp")
			end
		end)
		fireButton.Activated:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("Fire")
		end)
	end

	if reloadButton then
		reloadButton.Activated:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("Reload")
		end)
	end

	if switchButton then
		switchButton.Activated:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("SwitchWeapon")
		end)
	end

	if scoreButton then
		scoreButton.Activated:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("ToggleScoreboard")
		end)
	end

	if crouchButton then
		crouchButton.Activated:Connect(function()
			if not MobileController.IsOrientationValid then return end
			clientAction:Fire("CrouchToggle")
		end)
	end
end

connectButtons()
applyLayout()
setScale()
updateOrientationState()
setEnabledByPlatformAndState()

gameState:GetPropertyChangedSignal("Value"):Connect(function()
	setEnabledByPlatformAndState()
end)
UserInputService.LastInputTypeChanged:Connect(setEnabledByPlatformAndState)

local cam = workspace.CurrentCamera
if cam then
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		updateOrientationState()
		updateOverlayAndButtons()
		setScale()
	end)
end

print("MobileController initialized")
