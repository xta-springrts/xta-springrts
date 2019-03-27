--[[

	- tornadoWeapons: weapons that set of tornados in a region

--]]

local earthquakeWeapons = {}

local weapons = {}
--	["peewee_emg_2018"] = { radius = 300, damage = 0.05, dRadius = 2, dDamage = 0.001, duration = 50,  protection = 0}
--}


for name,data in pairs(WeaponDefNames) do
	local weaponDefID = WeaponDefNames[name].id
	local cp = WeaponDefs[weaponDefID].customParams
	if cp ~= nil then
		if cp.earthquake_radius then
			weapons[name] = {
				['radius'] = WeaponDefs[weaponDefID].customParams.earthquake_radius
			}
		end
	end
	if weapons[name] then
		earthquakeWeapons[data.id] = weapons[name]
	end
end

return earthquakeWeapons

