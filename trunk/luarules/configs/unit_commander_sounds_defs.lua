local CommanderUnitDefs = {
	[ UnitDefNames["arm_commander"   ].id ] = UnitDefNames["arm_commander"   ],
	[ UnitDefNames["arm_nincommander"].id ] = UnitDefNames["arm_nincommander"],
	[ UnitDefNames["arm_u0commander" ].id ] = UnitDefNames["arm_u0commander" ],
	[ UnitDefNames["arm_ucommander"  ].id ] = UnitDefNames["arm_ucommander"  ], -- NOTE: not "arm_u1commander"
	[ UnitDefNames["arm_u2commander" ].id ] = UnitDefNames["arm_u2commander" ],
	[ UnitDefNames["arm_u3commander" ].id ] = UnitDefNames["arm_u3commander" ],
	[ UnitDefNames["arm_u4commander" ].id ] = UnitDefNames["arm_u4commander" ],

	[ UnitDefNames["core_commander"   ].id ] = UnitDefNames["core_commander"   ],
	[ UnitDefNames["core_nincommander"].id ] = UnitDefNames["core_nincommander"],
	[ UnitDefNames["core_u0commander" ].id ] = UnitDefNames["core_u0commander" ],
	[ UnitDefNames["core_ucommander"  ].id ] = UnitDefNames["core_ucommander"  ], -- NOTE: not "core_u1commander"
	[ UnitDefNames["core_u2commander" ].id ] = UnitDefNames["core_u2commander" ],
	[ UnitDefNames["core_u3commander" ].id ] = UnitDefNames["core_u3commander" ],
	[ UnitDefNames["core_u4commander" ].id ] = UnitDefNames["core_u4commander" ],
}

-- TODO: add a denied-sound when reclaiming or capturing fails, DukeNukem3D F-key taunts
local CommanderSounds = {
	CommanderUpgraded                  = "sounds/commander/comm_upgraded.wav",
	CommanderHumiliated                = "sounds/commander/comm_humiliated.wav",
	CommanderRepaired                  = "sounds/commander/comm_regeneration.wav",
	CommanderHolyTargetDestroyed       = "sounds/commander/comm_holy_target_destroyed.wav",
	CommanderImpressiveTargetDestroyed = "sounds/commander/comm_impressive_target_destroyed.wav",
	CommanderPerfectTargetsKilled      = "sounds/commander/comm_perfect_targets_killed.wav",
	CommanderExcellentTargetsKilled    = "sounds/commander/comm_excellent_targets_killed.wav",
	CommanderCloaked                   = "sounds/commander/comm_cloaked.wav",
	CommanderSongs = {
		[ UnitDefNames["arm_commander"   ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_nincommander"].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_u0commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_ucommander"  ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_u2commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_u3commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["arm_u4commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/armcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},

		[ UnitDefNames["core_commander"   ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_nincommander"].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_u0commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_ucommander"  ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_u2commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_u3commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
		[ UnitDefNames["core_u4commander" ].id ] = {[0] = "sounds/honk.wav", [1] = "sounds/corcom1.wav", [2] = "sounds/commander/comm_omelette_song.wav", [3] = "sounds/commander/comm_omelette_speech.wav", [4] = "sounds/sing.wav"},
	},
	CommanderTaunts = {
		[ UnitDefNames["arm_commander"   ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_nincommander"].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_u0commander" ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_ucommander"  ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_u2commander" ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_u3commander" ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},
		[ UnitDefNames["arm_u4commander" ].id ] = {[0] = "sounds/commander/arm_comm_taunt_3.wav", [1] = "sounds/commander/arm_comm_taunt_2.wav", [2] = "sounds/commander/arm_comm_taunt_1.wav"},

		[ UnitDefNames["core_commander"   ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_nincommander"].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_u0commander" ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_ucommander"  ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_u2commander" ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_u3commander" ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
		[ UnitDefNames["core_u4commander" ].id ] = {[0] = "sounds/commander/core_comm_taunt_3.wav", [1] = "sounds/commander/core_comm_taunt_2.wav", [2] = "sounds/commander/core_comm_taunt_1.wav"},
	},
	CommanderDamaged = {
		[0] = "sounds/commander/arm_comm_damage_25.wav",
		[1] = "sounds/commander/arm_comm_damage_50.wav",
		[2] = "sounds/commander/arm_comm_damage_75.wav",
		[3] = "sounds/commander/arm_comm_damage_100.wav",

		[4] = "sounds/commander/core_comm_damage_25.wav",
		[5] = "sounds/commander/core_comm_damage_50.wav",
		[6] = "sounds/commander/core_comm_damage_75.wav",
		[7] = "sounds/commander/core_comm_damage_100.wav",
	},
}

local CommanderTargets = {
	HolyTargetDefs = {
		[0] = UnitDefNames["arm_retaliator"],
		[1] = UnitDefNames["arm_vulcan"],
		[2] = UnitDefNames["core_krogoth"],
		[3] = UnitDefNames["core_silencer"],
		[4] = UnitDefNames["core_buzzsaw"],
	},
	ImpressiveTargetDefs = {
		[ 0] = UnitDefNames["arm_annihilator"],
		[ 1] = UnitDefNames["arm_big_bertha"],
		[ 2] = UnitDefNames["arm_millenium"],
		[ 3] = UnitDefNames["arm_penetrator"],
		[ 4] = UnitDefNames["core_doomsday_machine"],
		[ 5] = UnitDefNames["core_goliath"],
		[ 6] = UnitDefNames["core_immolator"],
		[ 7] = UnitDefNames["core_intimidator"],
		[ 8] = UnitDefNames["core_mobile_artilleryold"], -- NOTE: "old"!
		[ 9] = UnitDefNames["core_sumo"],
		[10] = UnitDefNames["core_viper"],
		[11] = UnitDefNames["core_warlord"],
	},
}

return CommanderUnitDefs, CommanderSounds, CommanderTargets
