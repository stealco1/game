local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ShopData = require(Shared:WaitForChild("ShopData"))
local InventoryManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("InventoryManager"):WaitForChild("InventoryManager"))
local EconomyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("EconomyManager"):WaitForChild("EconomyManager"))

local UIRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UIRemotes")
local BuyWeapon = UIRemotes:WaitForChild("BuyWeapon")
local ShopPurchaseResult = UIRemotes:WaitForChild("ShopPurchaseResult")

local ShopManager = {}
local initialized = false
local purchaseLockByUserId = {}

local function reject(player, code, weaponName)
	ShopPurchaseResult:FireClient(player, {
		Success = false,
		Code = code,
		WeaponName = weaponName,
		Coins = EconomyManager.GetCoins(player),
	})
end

local function success(player, weaponName)
	ShopPurchaseResult:FireClient(player, {
		Success = true,
		Code = "Purchased",
		WeaponName = weaponName,
		Coins = EconomyManager.GetCoins(player),
	})
end

local function validateItem(weaponName)
	if typeof(weaponName) ~= "string" then return nil end
	local item = ShopData[weaponName]
	if typeof(item) ~= "table" then return nil end
	if typeof(item.Price) ~= "number" then return nil end
	if item.Price < 0 then return nil end
	if typeof(item.Category) ~= "string" then return nil end
	return item
end

function ShopManager.Purchase(player, weaponName)
	local item = validateItem(weaponName)
	if not item then
		reject(player, "InvalidWeapon", weaponName)
		return false
	end

	if InventoryManager.OwnsWeapon(player, weaponName) then
		reject(player, "AlreadyOwned", weaponName)
		return false
	end

	local okSpend = true
	if item.Price > 0 then
		okSpend = EconomyManager.TrySpendCoins(player, item.Price)
	end
	if not okSpend then
		reject(player, "InsufficientFunds", weaponName)
		return false
	end

	local added = InventoryManager.AddOwnedWeapon(player, weaponName, item.Category)
	if not added then
		if item.Price > 0 then
			EconomyManager.AddCoins(player, item.Price)
		end
		reject(player, "PurchaseFailed", weaponName)
		return false
	end

	EconomyManager.QueueSave(player, false)
	success(player, weaponName)
	return true
end

function ShopManager.Init()
	if initialized then return end
	initialized = true

	BuyWeapon.OnServerEvent:Connect(function(player, weaponName)
		if not player or not player.Parent then return end
		local now = os.clock()
		local last = purchaseLockByUserId[player.UserId] or 0
		if now - last < 0.35 then
			reject(player, "TooFast", weaponName)
			return
		end
		purchaseLockByUserId[player.UserId] = now
		ShopManager.Purchase(player, weaponName)
	end)
end

ShopManager.Init()

return ShopManager
