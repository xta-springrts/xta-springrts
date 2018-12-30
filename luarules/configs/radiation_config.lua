--[[


For now only a few of the mechanics work

	working:
	1. radiation increase/decrease in radius and damage levels (dDamage, dRadius)

	TODO: (not working)
	2. add option for self damage = true/false
	3. fix funcitonality of radiation after unit has died (area on map)(maybe it works-duration param)
	4. add unit to a radiation table when an event happens (unit get nuked ot unit fires or ...)
	5. add unit list that are not effected by the radiation
	6. add some kind of cleaning unit that can remove radiation (reduce it)

--]]

local radiationWeapons = {}

local weapons = {}
--	["peewee_emg_2018"] = { radius = 300, damage = 0.05, dRadius = 2, dDamage = 0.001, duration = 50,  protection = 0}
--}


for name,data in pairs(WeaponDefNames) do
	local weaponDefID = WeaponDefNames[name].id
	local cp = WeaponDefs[weaponDefID].customParams
	if cp ~= nil then
		if cp.radiation_radius then
			weapons[name] = {
				['radius'] = WeaponDefs[weaponDefID].customParams.radiation_radius,
				['damage'] = WeaponDefs[weaponDefID].customParams.radiation_damage,
				['dRadius'] = WeaponDefs[weaponDefID].customParams.radiation_dradius,
				['dDamage'] = WeaponDefs[weaponDefID].customParams.radiation_ddamage,
				['duration'] = WeaponDefs[weaponDefID].customParams.radiation_duration,
				['protection'] = WeaponDefs[weaponDefID].customParams.radiation_protection
			}
		end
	end
	if weapons[name] then
		radiationWeapons[data.id] = weapons[name]
	end
end

local radiationUnits = {

	-- 1. thermal power units

	["arm_geothermal_powerplant"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["core_geothermal_powerplant"] = {
			['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05,
	},

	-- 2. fusion

	["arm_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["arm_mobile_fusion"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["arm_underwater_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["arm_cloakable_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["core_light_fusion_power_plant"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["core_cloakable_fusion_power_plant"] = {
				['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["core_fusion_power_plant"] = {
			['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},
	["core_underwater_fusion_power_plant"] = {
			['radius'] = 100,
				['damage'] = 0.00001,
				['dRadius'] = 0.1,
				['dDamage'] = 0.00001,
				['duration'] = 5000,
				['protection'] = 0.05
	},

	--2. ??

}

return radiationWeapons, radiationUnits
