local zombieDefs = {}

for unitDefName, unitDef in pairs(UnitDefs) do
	zombieDefs[unitDef.id] = {
		respawnTime = Game.gameSpeed * 15,

		allowZombieSpawn = true, 
		allowRepeatSpawn = false,
		allowDebrisSpawn = true,
		
		allowTeamKillSpawn = true,
		allowSelfKillSpawn = true,
	}
end

local captureUnitDefs = {
	[ UnitDefNames["arm_cappy"].id ] 						= UnitDefNames["arm_cappy"   ],
	[ UnitDefNames["arm_commander"].id ] 					= UnitDefNames["arm_commander"   ],
	[ UnitDefNames["arm_decoy_commander"].id ] 				= UnitDefNames["arm_decoy_commander"   ],
	[ UnitDefNames["arm_decoy_ucommander"].id ] 			= UnitDefNames["arm_decoy_ucommander"   ],
	[ UnitDefNames["arm_decoy_ucommander_core"].id ] 		= UnitDefNames["arm_decoy_ucommander_core"   ],
	[ UnitDefNames["arm_nincommander"].id ] 				= UnitDefNames["arm_nincommander"   ],
	[ UnitDefNames["arm_noruas"].id ] 						= UnitDefNames["arm_noruas"   ],
	[ UnitDefNames["arm_scommander"].id ] 					= UnitDefNames["arm_scommander"   ],
	[ UnitDefNames["arm_u0commander"].id ] 					= UnitDefNames["arm_u0commander"   ],
	[ UnitDefNames["arm_u2commander"].id ] 					= UnitDefNames["arm_u2commander"   ],
	[ UnitDefNames["arm_u3commander"].id ] 					= UnitDefNames["arm_u3commander"   ],
	[ UnitDefNames["arm_u4commander"].id ] 					= UnitDefNames["arm_u4commander"   ],
	[ UnitDefNames["arm_ucommander"].id ] 					= UnitDefNames["arm_ucommander"   ],
	[ UnitDefNames["commando"].id ] 						= UnitDefNames["commando"   ],
	[ UnitDefNames["core_cappy"].id ] 						= UnitDefNames["core_cappy"   ],
	[ UnitDefNames["core_commander"].id ]		 			= UnitDefNames["core_commander"   ],
	[ UnitDefNames["core_decoy_commander"].id ] 			= UnitDefNames["core_decoy_commander"   ],
	[ UnitDefNames["core_decoy_ucommander"].id ] 			= UnitDefNames["core_decoy_ucommander"   ],
	[ UnitDefNames["core_decoy_ucommander_arm"].id ] 		= UnitDefNames["core_decoy_ucommander_arm"   ],
	[ UnitDefNames["core_nincommander"].id ] 				= UnitDefNames["core_nincommander"   ],
	[ UnitDefNames["core_scommander"].id ] 					= UnitDefNames["core_scommander"   ],
	[ UnitDefNames["core_u0commander"].id ] 				= UnitDefNames["core_u0commander"   ],
	[ UnitDefNames["core_u2commander"].id ] 				= UnitDefNames["core_u2commander"   ],
	[ UnitDefNames["core_u3commander"].id ] 				= UnitDefNames["core_u3commander"   ],
	[ UnitDefNames["core_u4commander"].id ] 				= UnitDefNames["core_u4commander"   ],
	[ UnitDefNames["core_ucommander"].id ] 					= UnitDefNames["core_ucommander"   ],
	[ UnitDefNames["noruas"].id ] 							= UnitDefNames["noruas"],
	[ UnitDefNames["lost_archnano"].id ] 					= UnitDefNames["lost_archnano"   ],
	[ UnitDefNames["lost_commander"].id ] 					= UnitDefNames["lost_commander"  ],
	[ UnitDefNames["lost_decoy_commander"].id ] 			= UnitDefNames["lost_decoy_commander"  ],
	[ UnitDefNames["lost_u0commander"].id ] 				= UnitDefNames["lost_u0commander"  ],
	[ UnitDefNames["lost_u2commander"].id ] 				= UnitDefNames["lost_u2commander"  ],
	[ UnitDefNames["lost_u3commander"].id ] 				= UnitDefNames["lost_u3commander"  ],
	[ UnitDefNames["lost_u4commander"].id ] 				= UnitDefNames["lost_u4commander"  ],
	[ UnitDefNames["lost_ucommander"].id ] 					= UnitDefNames["lost_ucommander"  ],
	[ UnitDefNames["guardian_commander"].id ] 					= UnitDefNames["guardian_commander"  ],
	--[ UnitDefNames["guardian_decoy_commander"].id ] 			= UnitDefNames["guardian_decoy_commander"  ],
	[ UnitDefNames["guardian_u0commander"].id ] 				= UnitDefNames["guardian_u0commander"  ],
	[ UnitDefNames["guardian_u2commander"].id ] 				= UnitDefNames["guardian_u2commander"  ],
	[ UnitDefNames["guardian_u3commander"].id ] 				= UnitDefNames["guardian_u3commander"  ],
	[ UnitDefNames["guardian_u4commander"].id ] 				= UnitDefNames["guardian_u4commander"  ],
	[ UnitDefNames["guardian_ucommander"].id ] 					= UnitDefNames["guardian_ucommander"  ],
	}
	
local napUnitDefs = {
	[ UnitDefNames["arm_atlas"].id ] 						= UnitDefNames["arm_atlas"],
	[ UnitDefNames["arm_bear"].id ] 						= UnitDefNames["arm_bear"],
	[ UnitDefNames["arm_hulk"].id ] 						= UnitDefNames["arm_hulk"],
	[ UnitDefNames["arm_ornith"].id ] 						= UnitDefNames["arm_ornith"],
	[ UnitDefNames["core_envoy"].id ] 						= UnitDefNames["core_envoy"],
	[ UnitDefNames["core_turtle"].id ] 						= UnitDefNames["core_turtle"],
	[ UnitDefNames["core_valkyrie"].id ] 					= UnitDefNames["core_valkyrie"],
	[ UnitDefNames["core_zeppelin"].id ] 					= UnitDefNames["core_zeppelin"],
	[ UnitDefNames["lost_ambassador"].id ] 					= UnitDefNames["lost_ambassador"  ],
	[ UnitDefNames["lost_pelican"].id ] 					= UnitDefNames["lost_pelican"  ],
	[ UnitDefNames["lost_robber"].id ] 						= UnitDefNames["lost_robber"  ],
	}

return zombieDefs,captureUnitDefs,napUnitDefs

