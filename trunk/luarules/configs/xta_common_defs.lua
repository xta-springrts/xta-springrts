-- Defines common tables that can be used in many gadgets and widgets

local CommanderUnitDefs = {
	[ UnitDefNames["arm_commander"   ].id ] = UnitDefNames["arm_commander"   ],
	[ UnitDefNames["arm_nincommander"].id ] = UnitDefNames["arm_nincommander"],
	[ UnitDefNames["arm_scommander"  ].id ] = UnitDefNames["arm_scommander"  ],
	[ UnitDefNames["arm_u0commander" ].id ] = UnitDefNames["arm_u0commander" ],
	[ UnitDefNames["arm_ucommander"  ].id ] = UnitDefNames["arm_ucommander"  ], -- NOTE: not "arm_u1commander"
	[ UnitDefNames["arm_u2commander" ].id ] = UnitDefNames["arm_u2commander" ],
	[ UnitDefNames["arm_u3commander" ].id ] = UnitDefNames["arm_u3commander" ],
	[ UnitDefNames["arm_u4commander" ].id ] = UnitDefNames["arm_u4commander" ],

	[ UnitDefNames["core_commander"   ].id ] = UnitDefNames["core_commander"   ],
	[ UnitDefNames["core_nincommander"].id ] = UnitDefNames["core_nincommander"],
	[ UnitDefNames["core_scommander"  ].id ] = UnitDefNames["core_scommander"  ],
	[ UnitDefNames["core_u0commander" ].id ] = UnitDefNames["core_u0commander" ],
	[ UnitDefNames["core_ucommander"  ].id ] = UnitDefNames["core_ucommander"  ], -- NOTE: not "core_u1commander"
	[ UnitDefNames["core_u2commander" ].id ] = UnitDefNames["core_u2commander" ],
	[ UnitDefNames["core_u3commander" ].id ] = UnitDefNames["core_u3commander" ],
	[ UnitDefNames["core_u4commander" ].id ] = UnitDefNames["core_u4commander" ],
	
	[ UnitDefNames["lost_commander"   ].id ] = UnitDefNames["lost_commander"   ],
	[ UnitDefNames["lost_u0commander" ].id ] = UnitDefNames["lost_u0commander" ],
	[ UnitDefNames["lost_ucommander"  ].id ] = UnitDefNames["lost_ucommander"  ], -- NOTE: not "lost_u1commander"
	[ UnitDefNames["lost_u2commander" ].id ] = UnitDefNames["lost_u2commander" ],
	[ UnitDefNames["lost_u3commander" ].id ] = UnitDefNames["lost_u3commander" ],
	[ UnitDefNames["lost_u4commander" ].id ] = UnitDefNames["lost_u4commander" ],
}

-- Define all D-Gun weapons except the fake ones
local DGunDefs = {
	[WeaponDefNames[  "arm_disintegrator"].id] = true,
	[WeaponDefNames[ "core_disintegrator"].id] = true,
	[WeaponDefNames["core_udisintegrator"].id] = true,
	[WeaponDefNames[ "uber_disintegrator"].id] = true,
	[WeaponDefNames[ "tll_disintegrator"].id] = true,
	[WeaponDefNames[ "tll_disintegrator3"].id] = true,
	[WeaponDefNames[ "tll_disintegrator2"].id] = true,
	[WeaponDefNames[ "guardian_disintegrator"].id] = true,
	[WeaponDefNames[ "guardian_disintegrator3"].id] = true,
	[WeaponDefNames[ "guardian_disintegrator4"].id] = true,
	[WeaponDefNames[ "guardian_disintegrator2"].id] = true,
}

--Define all wall and dragon's teeth. Used for ismo award.
local dtTable = {
	[UnitDefNames["arm_dragons_teeth"].id] 				= true,
	[UnitDefNames["arm_floating_dragons_teeth"].id] 	= true,
	[UnitDefNames["core_dragons_teeth"].id] 			= true,
	[UnitDefNames["core_floating_dragons_teeth"].id] 	= true,
	[UnitDefNames["arm_fortification_wall"].id] 		= true,
	[UnitDefNames["core_fortification_wall"].id] 		= true,
	-- Addition of TLL stuff
	[UnitDefNames["lost_dragons_teeth"].id] 			= true,
	[UnitDefNames["lost_floating_dragons_teeth"].id] 	= true,
	[UnitDefNames["lost_fortification_wall"].id] 		= true,
	-- Guardians only have dt
	[UnitDefNames["guardian_dragons_teeth"].id] 		= true,
}	

--Define all T2 units including moho stuff. The defintion of T2 is: something that exists in an advanced version.
local t2Table = {
	[UnitDefNames["arm_adv_aircraft_plant"].id] 		= true,
	[UnitDefNames["arm_adv_construction_aircraft"].id]	= true,
	[UnitDefNames["arm_adv_construction_kbot"].id] 		= true,
	[UnitDefNames["arm_adv_construction_sub"].id] 		= true,
	[UnitDefNames["arm_adv_construction_vehicle"].id] 	= true,
	[UnitDefNames["arm_adv_kbot_lab"].id] 				= true,
	[UnitDefNames["arm_adv_shipyard"].id] 				= true,
	[UnitDefNames["arm_adv_vehicle_plant"].id] 			= true,
	[UnitDefNames["arm_advanced_radar_tower"].id] 		= true,
	[UnitDefNames["arm_advanced_sonar_station"].id] 	= true,
	[UnitDefNames["arm_advanced_torpedo_launcher"].id] 	= true,
	[UnitDefNames["arm_moho_metal_maker"].id] 			= true,
	[UnitDefNames["arm_moho_mine"].id] 					= true,
	[UnitDefNames["arm_underwater_moho_mine"].id] 		= true,
	[UnitDefNames["core_adv_aircraft_plant"].id] 		= true,
	[UnitDefNames["core_adv_construction_aircraft"].id] = true,
	[UnitDefNames["core_adv_construction_kbot"].id] 	= true,
	[UnitDefNames["core_adv_construction_sub"].id] 		= true,
	[UnitDefNames["core_adv_construction_vehicle"].id] 	= true,
	[UnitDefNames["core_adv_kbot_lab"].id] 				= true,
	[UnitDefNames["core_adv_shipyard"].id] 				= true,
	[UnitDefNames["core_adv_vehicle_plant"].id] 		= true,
	[UnitDefNames["core_advanced_radar_tower"].id] 		= true,
	[UnitDefNames["core_advanced_sonar_station"].id] 	= true,
	[UnitDefNames["core_advanced_torpedo_launcher"].id] = true,
	[UnitDefNames["core_moho_metal_maker"].id] 			= true,
	[UnitDefNames["core_moho_mine"].id] 				= true,
	[UnitDefNames["core_underwater_moho_mine"].id] 		= true,
	[UnitDefNames["lost_advanced_radar_tower"].id] 		= true,
	[UnitDefNames["lost_advanced_sonar_station"].id] 	= true,
	[UnitDefNames["lost_advanced_torpedo_launcher"].id] = true,
	[UnitDefNames["lost_adv_aircraft_plant"].id] 		= true,
	[UnitDefNames["lost_adv_construction_aircraft"].id] = true,
	[UnitDefNames["lost_adv_construction_kbot"].id] 	= true,
	[UnitDefNames["lost_adv_construction_sub"].id] 		= true,
	[UnitDefNames["lost_adv_construction_vehicle"].id] 	= true,
	[UnitDefNames["lost_adv_kbot_lab"].id] 				= true,
	[UnitDefNames["lost_adv_shipyard"].id] 				= true,
	[UnitDefNames["lost_adv_vehicle_plant"].id] 		= true,
	[UnitDefNames["lost_moho_metal_maker"].id] 			= true,
	[UnitDefNames["lost_moho_mine"].id] 				= true,
	[UnitDefNames["lost_underwater_moho_mine"].id] 		= true,
	--Note: no guardian units yet
}




return CommanderUnitDefs, DGunDefs, dtTable, t2Table