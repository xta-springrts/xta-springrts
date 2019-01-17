--[[


	For parameter description see radiation gadget

	- radiationWeapons: weapons that deal radiation
	- radiationUnits: units that have radiation

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
				['protection'] = WeaponDefs[weaponDefID].customParams.radiation_protection,
				['maxradius'] = WeaponDefs[weaponDefID].customParams.radiation_maxradius,
				['hitradius'] = WeaponDefs[weaponDefID].customParams.radiation_hitradius
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
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0,
				['maxradius'] = 500
	},
	["core_geothermal_powerplant"] = {
			['radius'] = 100,
			['damage'] = 0.05,
			['dRadius'] = 0.1,
			['dDamage'] = 0.001,
			['duration'] = 500,
			['protection'] = 0,
			['maxradius'] = 500
	},

	-- 2. fusion

	["arm_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.01,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["arm_mobile_fusion"] = {
				['radius'] = 100,
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["arm_underwater_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["arm_cloakable_fusion_reactor"] = {
				['radius'] = 100,
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["core_light_fusion_power_plant"] = {
				['radius'] = 100,
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["core_cloakable_fusion_power_plant"] = {
				['radius'] = 100,
				['damage'] = 0.05,
				['dRadius'] = 0.1,
				['dDamage'] = 0.001,
				['duration'] = 500,
				['protection'] = 0.0001,
				['maxradius'] = 1000
	},
	["core_fusion_power_plant"] = {
			['radius'] = 100,
			['damage'] = 0.05,
			['dRadius'] = 0.1,
			['dDamage'] = 0.001,
			['duration'] = 500,
			['protection'] = 0.0001,
			['maxradius'] = 1000
	},
	["core_underwater_fusion_power_plant"] = {
			['radius'] = 100,
			['damage'] = 0.05,
			['dRadius'] = 0.1,
			['dDamage'] = 0.001,
			['duration'] = 500,
			['protection'] = 0.0001,
			['maxradius'] = 1000
	},


}

return radiationWeapons, radiationUnits
