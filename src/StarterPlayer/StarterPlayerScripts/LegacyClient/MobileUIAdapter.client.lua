local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(0.5)

local function updateUIScale()
	local mainUI = playerGui:FindFirstChild("MainUI")
	if not mainUI then return end
	
	local uiScale = mainUI:FindFirstChild("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = mainUI
	end
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local vp = camera.ViewportSize
	local minDim = math.min(vp.X, vp.Y)
	
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		uiScale.Scale = math.max(0.6, math.min(1.2, minDim / 700))
	else
		uiScale.Scale = 1
	end
end

task.wait(1)
updateUIScale()

local camera = workspace.CurrentCamera
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)
end
