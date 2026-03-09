local UIManager = {}
local TweenService = game:GetService("TweenService")

local ACCENT_COLOR = Color3.fromRGB(0, 212, 255)
local DARK_BG = Color3.fromRGB(18, 18, 22)
local HOVER_COLOR = Color3.fromRGB(40, 45, 55)

function UIManager.TweenIn(gui, duration)
	duration = duration or 0.3
	gui.Visible = true
	gui.GroupTransparency = 1
	local tween = TweenService:Create(gui, TweenInfo.new(duration, Enum.EasingStyle.Quad), {GroupTransparency = 0})
	tween:Play()
	return tween
end

function UIManager.TweenOut(gui, duration, callback)
	duration = duration or 0.25
	local tween = TweenService:Create(gui, TweenInfo.new(duration, Enum.EasingStyle.Quad), {GroupTransparency = 1})
	tween:Play()
	tween.Completed:Connect(function()
		gui.Visible = false
		if callback then callback() end
	end)
	return tween
end

function UIManager.ButtonHover(button, normalColor, hoverColor)
	normalColor = normalColor or HOVER_COLOR
	hoverColor = hoverColor or ACCENT_COLOR
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundColor3 = normalColor}):Play()
	end)
end

function UIManager.CreateRoundedFrame(parent, size, pos, name)
	local frame = Instance.new("Frame")
	frame.Name = name or "Frame"
	frame.Size = size or UDim2.new(1, 0, 1, 0)
	frame.Position = pos or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = DARK_BG
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	return frame
end

return UIManager
