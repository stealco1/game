local WeaponBase = {}

function WeaponBase.new(config)
	local self = setmetatable({}, {__index = WeaponBase})
	self.Config = config
	self.Ammo = config.Ammo
	self.ReserveAmmo = config.ReserveAmmo or config.MaxReserve or 0
	self.IsReloading = false
	self.LastFire = 0
	return self
end

function WeaponBase:CanFire()
	return self.Ammo > 0 and not self.IsReloading and (tick() - self.LastFire) >= self.Config.FireRate
end

function WeaponBase:CanReload()
	return self.Ammo < self.Config.MaxAmmo and self.ReserveAmmo > 0 and not self.IsReloading
end

function WeaponBase:Fire()
	if not self:CanFire() then return false end
	self.Ammo = self.Ammo - 1
	self.LastFire = tick()
	return true
end

function WeaponBase:Reload()
	if not self:CanReload() then return false end
	self.IsReloading = true
	task.delay(self.Config.ReloadTime, function()
		local need = self.Config.MaxAmmo - self.Ammo
		local take = math.min(need, self.ReserveAmmo)
		self.Ammo = self.Ammo + take
		self.ReserveAmmo = self.ReserveAmmo - take
		self.IsReloading = false
	end)
	return true
end

return WeaponBase
