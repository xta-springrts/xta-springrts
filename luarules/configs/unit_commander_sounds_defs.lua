local Echo = Spring.Echo

-- Move to common config file
local CommanderUnitDefs = include("LuaRules/Configs/xta_common_defs.lua")

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
		[ UnitDefNames["arm_commander"].id ] = {
			[0] = "sounds/unit/sing.wav",
			[1] = "sounds/unit/armcom1.wav",
			[2] = "sounds/unit/armcom2.wav",
			[3] = "sounds/unit/honk.wav",
			[4] = "sounds/commander/comm_omelette_song.wav",
			[5] = "sounds/commander/comm_omelette_speech.wav",
			[6] = "sounds/commander/comm_trololo_intro.wav",
			[7] = "sounds/commander/comm_trololo_outro.wav",
			[8] = "sounds/commander/comm_gast_sample.wav",
		},

		[ UnitDefNames["arm_nincommander"].id ] = {},
		[ UnitDefNames["arm_scommander"  ].id ] = {},
		[ UnitDefNames["arm_u0commander" ].id ] = {},
		[ UnitDefNames["arm_ucommander"  ].id ] = {},
		[ UnitDefNames["arm_u2commander" ].id ] = {},
		[ UnitDefNames["arm_u3commander" ].id ] = {},
		[ UnitDefNames["arm_u4commander" ].id ] = {},

		[ UnitDefNames["core_commander"].id ] = {
			[0] = "sounds/unit/sing2.wav",
			[1] = "sounds/unit/corcom1.wav",
			[2] = "sounds/unit/corcom2.wav",
			[3] = "sounds/unit/honk2.wav",
			[4] = "sounds/commander/comm_omelette_song.wav",
			[5] = "sounds/commander/comm_omelette_speech.wav",
			[6] = "sounds/commander/comm_trololo_intro.wav",
			[7] = "sounds/commander/comm_trololo_outro.wav",
			[8] = "sounds/commander/comm_gast_sample.wav",
		},

		[ UnitDefNames["core_nincommander"].id ] = {},
		[ UnitDefNames["core_scommander"  ].id ] = {},
		[ UnitDefNames["core_u0commander" ].id ] = {},
		[ UnitDefNames["core_ucommander"  ].id ] = {},
		[ UnitDefNames["core_u2commander" ].id ] = {},
		[ UnitDefNames["core_u3commander" ].id ] = {},
		[ UnitDefNames["core_u4commander" ].id ] = {},
		
		[ UnitDefNames["lost_commander"].id ] = {
			[0] = "sounds/commander/lost_sing1.wav",
			[1] = "sounds/commander/lost_sing2.wav",
			[2] = "sounds/commander/lost_sing3.wav",
			[3] = "sounds/commander/lost_sing4.wav",
		},

		[ UnitDefNames["lost_u0commander" ].id ] = {},
		[ UnitDefNames["lost_ucommander"  ].id ] = {},
		[ UnitDefNames["lost_u2commander" ].id ] = {},
		[ UnitDefNames["lost_u3commander" ].id ] = {},
		[ UnitDefNames["lost_u4commander" ].id ] = {},
	},
	
	GLHFSongs = {
		[ UnitDefNames["arm_commander"].id ] = {
			[0] = "sounds/glhf/glhf_A1.wav",
			[1] = "sounds/glhf/glhf_A2.wav",
			[2] = "sounds/glhf/glhf_A3.wav",
			[3] = "sounds/glhf/glhf_A4.wav",
			[4] = "sounds/glhf/glhf_A5.wav",
			[5] = "sounds/glhf/glhf_Afi.wav",
			--[6] = "sounds/glhf/glhf_is.wav",
			--[6] = "sounds/glhf/glhf_sw.wav",
			--[7] = "sounds/glhf/glhf_jp.wav",
			--[8] = "sounds/glhf/glhf_de.wav",	
		},
		[ UnitDefNames["arm_nincommander"].id ] = {},
		[ UnitDefNames["arm_scommander"  ].id ] = {},
		[ UnitDefNames["arm_u0commander" ].id ] = {},
		[ UnitDefNames["arm_ucommander"  ].id ] = {},
		[ UnitDefNames["arm_u2commander" ].id ] = {},
		[ UnitDefNames["arm_u3commander" ].id ] = {},
		[ UnitDefNames["arm_u4commander" ].id ] = {},
		
		[ UnitDefNames["core_commander"].id ] = {
			[0] = "sounds/glhf/glhf_C1.wav",
			[1] = "sounds/glhf/glhf_C2.wav",
			[2] = "sounds/glhf/glhf_C3.wav",
			[3] = "sounds/glhf/glhf_C4.wav",
			[4] = "sounds/glhf/glhf_C5.wav",
			[5] = "sounds/glhf/glhf_Cfr.wav",
			--[6] = "sounds/glhf/glhf_6.wav",
			--[7] = "sounds/glhf/glhf_6.wav",
			--[8] = "sounds/glhf/glhf_6.wav",
			--[9] = "sounds/glhf/glhf_6.wav",
		},
		[ UnitDefNames["core_nincommander"].id ] = {},
		[ UnitDefNames["core_scommander"  ].id ] = {},
		[ UnitDefNames["core_u0commander" ].id ] = {},
		[ UnitDefNames["core_ucommander"  ].id ] = {},
		[ UnitDefNames["core_u2commander" ].id ] = {},
		[ UnitDefNames["core_u3commander" ].id ] = {},
		[ UnitDefNames["core_u4commander" ].id ] = {},
		
		[ UnitDefNames["lost_commander"].id ] = {
			[0] = "sounds/glhf/glhf_L1.wav",
			[1] = "sounds/glhf/glhf_L2.wav",
			[2] = "sounds/glhf/glhf_L3.wav",
			[3] = "sounds/glhf/glhf_Lpt.wav",	
		},
		[ UnitDefNames["lost_u0commander" ].id ] = {},
		[ UnitDefNames["lost_ucommander"  ].id ] = {},
		[ UnitDefNames["lost_u2commander" ].id ] = {},
		[ UnitDefNames["lost_u3commander" ].id ] = {},
		[ UnitDefNames["lost_u4commander" ].id ] = {},
		
		
	},
	
	TYSongs = {
		[ UnitDefNames["arm_commander"].id ] = {
			[0] = "sounds/glhf/ty_arm_1.wav",
			[1] = "sounds/glhf/ty_arm_2.wav",
			[2] = "sounds/glhf/ty_arm_3.wav",
			[3] = "sounds/glhf/ty_arm_4.wav",
			[4] = "sounds/glhf/ty_arm_5.wav",
			[5] = "sounds/glhf/ty_arm_6.wav",
			
		},
		[ UnitDefNames["arm_nincommander"].id ] = {},
		[ UnitDefNames["arm_scommander"  ].id ] = {},
		[ UnitDefNames["arm_u0commander" ].id ] = {},
		[ UnitDefNames["arm_ucommander"  ].id ] = {},
		[ UnitDefNames["arm_u2commander" ].id ] = {},
		[ UnitDefNames["arm_u3commander" ].id ] = {},
		[ UnitDefNames["arm_u4commander" ].id ] = {},
		
		[ UnitDefNames["core_commander"].id ] = {
			[0] = "sounds/glhf/ty_core_1.wav",
			[1] = "sounds/glhf/ty_core_2.wav",
			[2] = "sounds/glhf/ty_core_3.wav",
			[3] = "sounds/glhf/ty_core_4.wav",
			[4] = "sounds/glhf/ty_core_5.wav",
			[5] = "sounds/glhf/ty_core_6.wav",
			
		},
		[ UnitDefNames["core_nincommander"].id ] = {},
		[ UnitDefNames["core_scommander"  ].id ] = {},
		[ UnitDefNames["core_u0commander" ].id ] = {},
		[ UnitDefNames["core_ucommander"  ].id ] = {},
		[ UnitDefNames["core_u2commander" ].id ] = {},
		[ UnitDefNames["core_u3commander" ].id ] = {},
		[ UnitDefNames["core_u4commander" ].id ] = {},
		
		[ UnitDefNames["lost_commander"].id ] = {
			[0] = "sounds/glhf/ty_lost_1.wav",
			[1] = "sounds/glhf/ty_lost_2.wav",
			[2] = "sounds/glhf/ty_lost_3.wav",
			[3] = "sounds/glhf/ty_lost_4.wav",
			[4] = "sounds/glhf/ty_lost_5.wav",
			[5] = "sounds/glhf/ty_lost_6.wav",
			
		},
		[ UnitDefNames["lost_u0commander" ].id ] = {},
		[ UnitDefNames["lost_ucommander"  ].id ] = {},
		[ UnitDefNames["lost_u2commander" ].id ] = {},
		[ UnitDefNames["lost_u3commander" ].id ] = {},
		[ UnitDefNames["lost_u4commander" ].id ] = {},	
		
	},
	
	CommanderTaunts = {
		[ UnitDefNames["arm_commander"].id ] = {
			[0] = "sounds/commander/arm_comm_taunt_3.wav",
			[1] = "sounds/commander/arm_comm_taunt_2.wav",
			[2] = "sounds/commander/arm_comm_taunt_1.wav",
			[3] = "sounds/commander/arm_comm_taunt_4.wav",
		},
		[ UnitDefNames["arm_nincommander"].id ] = {},
		[ UnitDefNames["arm_scommander"  ].id ] = {},
		[ UnitDefNames["arm_u0commander" ].id ] = {},
		[ UnitDefNames["arm_ucommander"  ].id ] = {},
		[ UnitDefNames["arm_u2commander" ].id ] = {},
		[ UnitDefNames["arm_u3commander" ].id ] = {},
		[ UnitDefNames["arm_u4commander" ].id ] = {},

		[ UnitDefNames["core_commander"].id ] = {
			[0] = "sounds/commander/core_comm_taunt_3.wav",
			[1] = "sounds/commander/core_comm_taunt_2.wav",
			[2] = "sounds/commander/core_comm_taunt_1.wav",
			[3] = "sounds/commander/core_comm_taunt_4.wav",
		},
		[ UnitDefNames["core_nincommander"].id ] = {},
		[ UnitDefNames["core_scommander"  ].id ] = {},
		[ UnitDefNames["core_u0commander" ].id ] = {},
		[ UnitDefNames["core_ucommander"  ].id ] = {},
		[ UnitDefNames["core_u2commander" ].id ] = {},
		[ UnitDefNames["core_u3commander" ].id ] = {},
		[ UnitDefNames["core_u4commander" ].id ] = {},
		
		[ UnitDefNames["lost_commander"].id ] = {
			[0] = "sounds/commander/lost_comm_taunt_3.wav",
			[1] = "sounds/commander/lost_comm_taunt_2.wav",
			[2] = "sounds/commander/lost_comm_taunt_1.wav",
			[3] = "sounds/commander/lost_comm_taunt_4.wav",
		},

		[ UnitDefNames["lost_u0commander" ].id ] = {},
		[ UnitDefNames["lost_ucommander"  ].id ] = {},
		[ UnitDefNames["lost_u2commander" ].id ] = {},
		[ UnitDefNames["lost_u3commander" ].id ] = {},
		[ UnitDefNames["lost_u4commander" ].id ] = {},
		
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
		
		[8] = "sounds/commander/lost_comm_damage_25.wav",
		[9] = "sounds/commander/lost_comm_damage_50.wav",
		[10] = "sounds/commander/lost_comm_damage_75.wav",
		[11] = "sounds/commander/lost_comm_damage_100.wav",
	},
}

local CommanderTargets = {
	HolyTargetDefs = {
		[0] = UnitDefNames["arm_retaliator"],
		[1] = UnitDefNames["arm_vulcan"],
		[2] = UnitDefNames["core_krogoth"],
		[3] = UnitDefNames["core_silencer"],
		[4] = UnitDefNames["core_buzzsaw"],
		[5] = UnitDefNames["lost_ht_satelight"],
		[6] = UnitDefNames["lost_devastator"],
		[7] = UnitDefNames["lost_thor_hammer"],
		[8] = UnitDefNames["lost_titan"],
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
		[ 8] = UnitDefNames["core_pillager"],
		[ 9] = UnitDefNames["core_sumo"],
		[10] = UnitDefNames["core_viper"],
		[11] = UnitDefNames["core_warlord"],
		[12] = UnitDefNames["lost_dreadnought"],
		[13] = UnitDefNames["lost_ht_storage"],
		[14] = UnitDefNames["lost_revenger"],
		[15] = UnitDefNames["lost_sling"],
		[16] = UnitDefNames["lost_obliterator"],
		[17] = UnitDefNames["lost_odin_mallet"],
		[18] = UnitDefNames["lost_convincer"],
		[19] = UnitDefNames["lost_loki"],
		[20] = UnitDefNames["lost_roaster"],
		[21] = UnitDefNames["lost_equalizer"],
		[22] = UnitDefNames["lost_viking"],
	},
}

local armComDefID = UnitDefNames["arm_commander" ].id
local corComDefID = UnitDefNames["core_commander"].id
local lostComDefID = UnitDefNames["lost_commander"].id

local comSongs = CommanderSounds.CommanderSongs
local comTaunts = CommanderSounds.CommanderTaunts
local comGLHF = CommanderSounds.GLHFSongs
local comTY = CommanderSounds.TYSongs

for unitDefID, sndTable in pairs(comSongs) do
	assert(type(sndTable) == type({}))

	if (unitDefID ~= armComDefID and unitDefID ~= corComDefID and unitDefID ~= lostComDefID) then
		local songsList = nil
		local unitDef = UnitDefs[unitDefID]
		
		-- use tag instead, make compatible with tll expansion
		if (unitDef.customParams and unitDef.customParams.side == "core") then
			songsList = comSongs[corComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "arm") then
			songsList = comSongs[armComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "lost") then
			songsList = comSongs[lostComDefID]
		end

		-- note: pairs because ipairs will never visit [0]
		for sndIndex, sndFile in pairs(songsList) do
			sndTable[sndIndex] = sndFile
		end
	end
end

for unitDefID, sndTable in pairs(comTaunts) do
	assert(type(sndTable) == type({}))

	if (unitDefID ~= armComDefID and unitDefID ~= corComDefID) then
		local tauntsList = nil
		local unitDef = UnitDefs[unitDefID]

		if (unitDef.customParams and unitDef.customParams.side == "core") then
			tauntsList = comTaunts[corComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "arm") then
			tauntsList = comTaunts[armComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "lost") then
			tauntsList = comTaunts[lostComDefID]
		end

		for sndIndex, sndFile in pairs(tauntsList) do
			sndTable[sndIndex] = sndFile
		end
	end
end

for unitDefID, sndTable in pairs(comGLHF) do
	assert(type(sndTable) == type({}))
	
	if (unitDefID ~= armComDefID and unitDefID ~= corComDefID) then
		
		local sayList = nil
		local unitDef = UnitDefs[unitDefID]

		if (unitDef.customParams and unitDef.customParams.side == "core") then
			sayList = comGLHF[corComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "arm") then
			sayList = comGLHF[armComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "lost") then
			sayList = comGLHF[lostComDefID]
		end

		for sndIndex, sndFile in pairs(sayList) do
			sndTable[sndIndex] = sndFile
		end
	end
end

for unitDefID, sndTable in pairs(comTY) do
	assert(type(sndTable) == type({}))
	
	if (unitDefID ~= armComDefID and unitDefID ~= corComDefID) then
		
		local sayList = nil
		local unitDef = UnitDefs[unitDefID]

		if (unitDef.customParams and unitDef.customParams.side == "core") then
			sayList = comTY[corComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "arm") then
			sayList = comTY[armComDefID]
		elseif (unitDef.customParams and unitDef.customParams.side == "lost") then
			sayList = comTY[lostComDefID]
		end

		for sndIndex, sndFile in pairs(sayList) do
			sndTable[sndIndex] = sndFile
		end
	end
end

-- for i,v in pairs(CommanderSounds) do
	-- Echo("sounds:",i,v)
	-- if type (v) == type({}) then
		-- for u,w in pairs (v) do
			-- Echo("Details:",u,w)
			-- if type (w) == type({}) then
				-- for x,y in pairs (w) do
					
					-- Echo("More details:",x,y)
					-- if i == 'GLHFSongs' then
						-- Echo("Now playing:",i,v,u,w,x,y)
						-- Spring.PlaySoundFile(y)
					-- end
				-- end
			-- end
		-- end
	-- end
-- end

return CommanderUnitDefs, CommanderSounds, CommanderTargets

