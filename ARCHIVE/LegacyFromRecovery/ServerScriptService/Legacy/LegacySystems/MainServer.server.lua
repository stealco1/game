-- MainServer: Initializes all systems and managers for the game
-- This script runs when the server starts

local ServerScriptService = game:GetService("ServerScriptService")
local Managers = ServerScriptService:WaitForChild("Managers")

local PlayerManager = require(Managers:WaitForChild("PlayerManager"))
local WeaponManager = require(Managers:WaitForChild("WeaponManager"))
local ShopManager = require(Managers:WaitForChild("ShopManager"))

-- Initialize all managers
PlayerManager.Init()
WeaponManager.Init()
ShopManager.Init()

print("Server Started")
