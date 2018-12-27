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


--local lib =  include("luarules/configs/gaia_wildlife_config_lib.lua") 								-- functions used for setups


local radiationConfig = {

	-- 1. thermal power units

	["arm_geothermal_powerplant"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["core_geothermal_powerplant"] = {
			['radius'] = 300,
			['damage'] = 0.05,
			['dRadius'] = 2,
			['dDamage'] = 0.001,
			['duration'] = 50,
			['self'] = 0.05
	},

	-- 2. fusion

	["arm_fusion_reactor"] = {
				['radius'] = 300,
				['damage'] = 0.01,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["arm_mobile_fusion"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["arm_underwater_fusion_reactor"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["arm_cloakable_fusion_reactor"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["core_light_fusion_power_plant"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["core_cloakable_fusion_power_plant"] = {
				['radius'] = 300,
				['damage'] = 0.05,
				['dRadius'] = 2,
				['dDamage'] = 0.001,
				['duration'] = 50,
				['self'] = 0.05
	},
	["core_fusion_power_plant"] = {
			['radius'] = 300,
			['damage'] = 0.05,
			['dRadius'] = 2,
			['dDamage'] = 0.001,
			['duration'] = 50,
			['self'] = 0.05
	},
	["core_underwater_fusion_power_plant"] = {
			['radius'] = 300,
			['damage'] = 0.05,
			['dRadius'] = 2,
			['dDamage'] = 0.001,
			['duration'] = 50,
			['self'] = 0.05
	},

	--2. ??

}

return radiationConfig

