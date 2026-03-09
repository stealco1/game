local HUDManager = {}
local TweenService = game:GetService("TweenService")

function HUDManager.UpdateHealth(player, current, max)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local hud = playerGui:FindFirstChild("HUD")
	if not hud then return end
	local healthBar = hud:FindFirstChild("HealthBar", true)
	if healthBar and healthBar:IsA("Frame") then
		local fill = healthBar:FindFirstChild("Fill")
		if fill then
			local ratio = math.clamp(current / math.max(max, 1), 0, 1)
			TweenService:Create(fill, TweenInfo.new(0.2), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
		end
	end
end

function HUDManager.UpdateAmmo(player, current, max)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local hud = playerGui:FindFirstChild("HUD")
	if not hud then return end
	local ammoLabel = hud:FindFirstChild("AmmoLabel")
	if ammoLabel then
		ammoLabel.Text = current .. " / " .. max
	end
end

function HUDManager.UpdateMoney(player, amount)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end
	local hud = playerGui:FindFirstChild("HUD")
	if not hud then return end
	local moneyLabel = hud:FindFirstChild("MoneyLabel")
	if moneyLabel then
		moneyLabel.Text = "$" .. tostring(amount)
	end
end

function HUDManager.AddKillFeedEntry(player, killer, victim)
	-- Handled by controller with RemoteEvent
end

return HUDManager
