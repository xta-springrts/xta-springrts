
--  Custom Options Definition Table format

--  NOTES:
--  - using an enumerated table lets you specify the options order

--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      the string used in the script.txt
--  name:     the displayed name
--  desc:     the description (could be used as a tooltip)
--  type:     the option type
--  def:      the default value;
--  min:      minimum value for number options
--  max:      maximum value for number options
--  step:     quantization step, aligned to the def value
--  maxlen:   the maximum string length for string options
--  items:    array of item strings for list options
--  scope:    'all', 'player', 'team', 'allyteam'      <<< not supported yet >>>
--

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Example ModOptions.lua 
--

local options = {
	{
		key  = "StartingResources",
		name = "Starting Resources",
		desc = "Sets storage and amount of resources that players will start with",
		type = "section",
	},
	{
		key  = 'xtagame',
		name = 'Game Options',
		desc = 'Optional game settings.',
		type = "section",
	},
	{
		key  = 'unitpacks',
		name = 'Unit packs',
		desc = 'Optional unit packs.',
		type = "section",
	},
	{
		key  = 'kothsection',
		name = 'King of the Hill Settings',
		desc = 'Settings for King of the Hill mode. Add extra boxes then actual teams to declare capture areas, can be more then one extra box.',
		type = "section",
	},
	{
		key  = 'zombiesection',
		name = 'Zombie-mode settings',
		desc = 'Settings for Zombie-mode.',
		type = "section",
	},
	{
		key  = 'multipers',
		name = 'Multiplier settings',
		desc = 'Settings for multipliers.',
		type = "section",
	},
	
	{
		key  = 'other',
		name = 'Experimental options',
		desc = 'Other non-homologated stuff',
		type = "section",
	},

		{
		key  = 'environment',
		name = 'Environment options',
		desc = 'World properties',
		type = "section",
		},

	--Removed till spawner is fixed
	{
		key  = 'Fleabowl',
		name = 'Fleabowl Stuff',
		desc = 'Use Ai Bots to set Flea difficulty.',
		type = "section",
	},
	
	{
		key  = "zombies",
		name = "Zombie Mode",
		desc = "All dead units respawn as hostile neutral zombies!",
		type = "bool",
		section = 'zombiesection',
		def  = false,
	},

	{
		key="mode",
		name="Game End Mode",
		desc="What it takes to eliminate a player or team\nkey: mode",
		type="list",
		section= 'xtagame',
		def="comends",
		items={
			{key="none", name="Never Die", desc="All players will stay alive regardless of what happens, game is never over"},
			{key="killall", name="Kill all enemy players", desc="Kill all enemies. Player will die if they have no units left."},
			{key="commander", name="Commander Ends", desc="Player will die if commander is killed"},
			{key="comends", name="Team Commander Ends", desc="Team will die if commanders of all players are killed."},
			{key="team", name="Kill all enemy units", desc="Kill all enemies. Dead players are retained until whole team dies"},
		}
	},
	{
		key  = "commander",
		name = "Starting Commander",
		desc = "Adjusts Starting Commander type or level\nkey: commander",
		type = "list",
		section= 'xtagame',
		def  = "choose",
		items = {
			{ key = "choose", name = "Let players choose in game", desc = "Let users choose in game between automatical and manual types"},
			{ key = "autoupgrade", name = "Automatic upgrades", desc = "Commander with automatical upgrades based on experience" },
			{ key = "noupgrade", name = "Manual upgrades, level 0 ", desc = "Commander with manual upgrades. Starting at base level" },
			{ key = "halfupgrade", name = "Manual upgrades, level 2", desc = "Commander with manual upgrades. Powerful lasers are added." },
			{ key = "fullupgrade", name = "Manual upgrades, level 4", desc = "Commander with manual upgrades. Insanely powerful (max upgrade)!" },
			{ key = "plain", name = "Plain commander", desc = "Commander with fixed abilities and stats, it can not be upgraded" },
			{ key = "comshooter", name = "Mini Com Shooter Game 0.1", desc = "Play Commander Shooter v0.1" },
			{ key = "decoystart", name = "Start With Decoy", desc = "Start with fake commander" },
			{ key = "capturethebase", name = "Capture the base", desc = "Capture the thing!" },
			{ key = "nincom", name = "Ninja Commanders!", desc = "Micro advised! JOKE START OPTION" }
		},
	},
	{
		key="mo_transportenemy",
		name="Enemy Transporting",
		desc="Toggle which enemy units you can kidnap with a transport vessel\nkey: mo_transportenemy",
		type="list",
		def="all",
		section="xtagame",
		items={
			{key="all", name="Allow All", desc="All enemy units can be napped"},
			{key="notcom", name="All But Commanders", desc="Only commanders are immune to napping"},
			{key="none", name="Disallow All", desc="No enemy units can be napped"},
		}
	},
	
	{
		key="mo_transporthover",
		name="Hovercraft Transporting",
		desc="Toggle whether hovercraft can be transported\nkey: mo_transporthover",
		type="list",
		def="1",
		section="xtagame",
		items={
			{key="1", name="Yes", desc="Hovercraft can be transported"},
			{key="0", name="No", desc="Hovercraft cannot be transported"},
		}
	},
	
	{
		key="qtpfs",
		name="Pathfinding system",
		desc="Which pathfinding system to use\nkey: qtpfs",
		type="list",
		section= 'xtagame',
		--section= 'xtagame',
		def="0",
		items={
			{key="0", name="Default", desc="Default Spring path finding engine"},
			{key="1", name="QTPFS", desc="QuadTree Path Finding System"},
		},
	},
	
	{
		key="lua_model",
		name="LuaThreadingModel",
		desc="Which luathreading system to use\nkey: luamodel",
		type="list",
		section= 'other',
		def="4",
		items={
			{key="1", name="1", desc="1"},
			{key="2", name="2", desc="2"},
			{key="3", name="3", desc="3"},
			{key="4", name="4", desc="4"},
			{key="5", name="5", desc="5"},
			{key="6", name="6", desc="6"},
		},
	},
		
	{
		key="reclaim_method",
		name="Reclaim method",
		desc="Which reclaim method to use\nkey: reclaim_method",
		type="list",
		section= 'xtagame',
		--section= 'xtagame',
		def="0",
		items={
			{key="0", name="Continuous", desc="Receive metal gradually for the duration of the reclaim"},
			{key="1", name="Discrete", desc="Receive all metal at once after reclaim finishes"},	
		},
	},
	{
		key    = "gravity",
		name   = "Cannon Velocity",
		desc   = "Set the projectile velocity for cannon weapons. Note: should be close to 0.25 (the number is actually weapon's local gravity).\nkey: gravity",
		type   = "number",
		section= 'other',
		def    = 0.25,
		min    = 0.15,
		max    = 1.25,
		step   = 0.05,
	},
	{
		key    = "airnocollide",
		name   = "Aircraft don't collide with each other",
		desc   = "Improves game performance and aircraft control at the expense of aircraft vs AA\nkey: airnocollide",
		type   = "bool",
		def    = true,
		section= 'other',
	},
	{
		key    = "space_mode",
		name   = "Allow aircraft and hovercraft on maps with no atmosphere",
		desc   = "If enabled map atmosphere condition will be ignored for aircraft and hovercraft\nkey: space_mode",
		type   = "bool",
		def    = true,
		section= 'other',
	},
	{
		key    = "nuke",
		name   = "Intercept nukes flying through coverage area",
		desc   = "If enabled all enemy nukes flying through coverage area of your antinuke but not targeting a spot inside it will be intercepted\nkey: nuke",
		type   = "bool",
		def    = true,
		section= "xtagame",
	},
	{
		key    = "mo_nowrecks",
		name   = "No Unit Wrecks",
		desc   = "Removes all unit wrecks from the game\nkey: mo_nowrecks",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "NewUnits",
		name   = "Disable Post Xta 8.1 units",
		desc   = "** Offical ** Disables the newer units that belong in xta versions past 8.1.\nkey: NewUnits",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	{
		key    = "xtaidUnits",
		name   = 'Enable "XTrA" Units',
		desc   = "** ThirdParty ** Adds XtrA unitpack. ARM/CORE Only. Author: Noruas\nkey: xtaidUnits",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	{
		key    = "tllUnits",
		name   = "Enable 'The Lost Legacy' faction?",
		desc   = "Adds The Lost Legacy unitpack. Ensure that you have selected 'choose in game' for the starting commander  option or this feature won't be possible. Author: Noruas\nkey: tllUnits",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	
	{
		key    = "gokUnits",
		name   = "Enable 'The Guardians of Kadesh' faction?",
		desc   = "Adds The Guardian of Kadesh unitpack. Ensure that you have selected 'choose in game' for the starting commander  option or this feature won't be possible. Author: Noruas\nkey: gokUnits",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	
	{
		key    = "talonUnits",
		name   = "Enable 'Talon' faction?",
		desc   = "Adds The Talon unitpack. Ensure that you have selected 'choose in game' for the starting commander  option or this feature won't be possible. Author: Noruas\nkey: talonUnits",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	
	{
		key    = "spidertortoise",
		name   = 'Enable "Spiders, Tortoise, & Towers" Units?',
		desc   = "** ThirdParty ** Adds Spiders, Tortoise, and Towers unitpack. Originally by TA: Mayhem and TA SECT! Author: Noruas\nkey: spidertortoise",
		type   = "bool",
		def    = false,
		section= "unitpacks",
	},
	{
		key    = "critters",
		name   = 'Enable cute animals?',
		desc   = "On some maps critters will they wiggle and wubble around\nkey: critters",
		type   = "bool",
		def    = true,
		section= "xtagame",
	},
	{
		key    = "wildlife",
		name   = 'Enable cute animals doing predation and growing plants?',
		desc   = "Wild life may have unexpected behavior\nkey: wildlife dominates maps",
		type   = "bool",
		def    = true,
		section= "xtagame",
	},
		{
		key    = "wildUnits",
		name   = 'lose control of part of your army?',
		desc   = "Some units that you build will have a mind of there own",
		type   = "bool",
		def    = true,
		section= "xtagame",
	},
	{
		key    = "buildspeed",
		name   = 'Enable variable production rate',
		desc   = "Enable variable production rate button to be added to build menu (may be expensive)\nkey: buildspeed",
		type   = "bool",
		def    = false,
		section= 'other',
	},
	{
		key    = "rockettoggle",
		name   = "Enable togglable rocket type?",
		desc   = "** ThirdParty ** Enable additional rocket type for several rocket/missile units  Author: Deadnight Warrior\nkey: rockettoggle",
		type   = "bool",
		def    = false,
		section= 'other',
	},
	{
		key    = "realscale",
		name   = "Use realistical size and range scale?",
		desc   = "** ThirdParty ** Make all sight, radar, sonar, jammer and weapon ranges and unit max velocities to realistical values. Not recomended on maps smaller than 30x30  Author: Deadnight Warrior\nkey: realscale",
		type   = "bool",
		def    = false,
		section= 'other',
	},
	{
		key    = "nocollide",
		name   = "Projectiles don't collide with friendly units",
		desc   = "** ThirdParty ** Author: Deadnight Warrior\nkey: nocollide",
		type   = "bool",
		def    = false,
		section= 'other',
	},
	{
		key    = "lowcpu",
		name   = "Low performance mode",
		desc   = "Reduces effects and makes fast fire weapons slower with more damage in order to reduce simulation requirements\nkey: lowcpu",
		type   = "bool",
		def    = false,
		section= 'other',
	},
	{
		key		= "dynamiclights",
		name	= "Dynamic lights",
		desc	= "Enable dynamic lighting effects.\nkey: dynamiclights",
		type	= "bool",
		section	= 'xtagame',
		def		= true,
	},
	
	{
		key		= "sounds",
		name	= "Sounds mode",
		desc	= "Is sound heard out of player's line of sight? \nkey: sounds",
		type	= "list",
		def		= "global",
		items={
			{key="local", name="Local", desc="Battle sounds are only heard in area in line-of-sight"},
			{key="global", name="Global", desc="battle sounds are always heard"},
			{key="dampened15", name="Dampened to 15 %", desc="Battle sounds are 15 % volume outside LOS"},
			{key="dampened30", name="Dampened to 30 %", desc="Battle sounds are 30 % volume outside LOS"},
			{key="dampened50", name="Dampened to 50 %", desc="Battle sounds are 50 % volume outside LOS"},
			{key="dampened65", name="Dampened to 65 %", desc="Battle sounds are 65 % volume outside LOS"},
		},
		section	= 'xtagame',
	},
	
	{
		key		= "debugmode",
		name	= "Debug Mode",
		desc	= "Enable debugging mode. Will allow /cheat by default, and load gadget profiler.\nkey: debugmode",
		type	= "bool",
		section	= 'other',
		def		= false,
	},
	
--	{
--		key    = "mo_coop",
--		name   = "Cooperative Mode",
--		desc   = "Adds an extra commander for comsharing teams",
--		type   = "bool",
--		def    = true,
--      },

	{
		key    = "earthquake",
		name   = 'earthquake',
		desc   = "The earth splits open!",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "comets",
		name   = 'comets',
		desc   = "Comets fall from the sky!",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "radiation",
		name   = 'radiation',
		desc   = "Units or terrein can do damage by radiation!",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "tornado",
		name   = 'tornado',
		desc   = "Tornedo's cross the map!",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "max_tornados",
		name   = "maximum tornados on the map",
		desc   = "Set how many tornados are on the map at a time.\nkey: maxComets",
		type   = "number",
		section= 'environment',
		def    = 10,
		min    = 0,
		max    = 50,
		step   = 1,
	},
	{
		key    = "max_cracks",
		name   = "maximum cracks on the map at a given time",
		desc   = "Set how many comets can maximal drop at a time.\nkey: max_cracks",
		type   = "number",
		section= 'environment',
		def    = 10,
		min    = 0,
		max    = 50,
		step   = 1,
	},
	{
		key    = "max_comets",
		name   = "maximum comets in rain",
		desc   = "Set how many comets can maximal drop at a time.\nkey: maxComets",
		type   = "number",
		section= 'environment',
		def    = 10,
		min    = 0,
		max    = 50,
		step   = 1,
	},
	{
		key    = "max_damage_comets",
		name   = "maximum comet damage",
		desc   = "Set how many damage comets give.\nkey: max_damage_comets",
		type   = "number",
		section= 'environment',
		def    = 500,
		min    = 0,
		max    = 100000,
		step   = 100,
	},
	{
		key    = "max_radius_damage_comets",
		name   = "maximum radius in which comets do damage",
		desc   = "Set how many damage comets give.\nkey: max_radius_damage_comets",
		type   = "number",
		section= 'environment',
		def    = 500,
		min    = 0,
		max    = 10000,
		step   = 50,
	},
	{
		key    = "time_delay_comet",
		name   = "Comet update time (min)",
		desc   = "Minutes new comets appear.\nkey: time_delay_comet",
		type   = "number",
		section= 'environment',
		def    = 1,
		min    = 1,
		max    = 100,
		step   = 0.5,
	},
	{
		key    = "duration_crack",
		name   = "Time duration cracks (min)",
		desc   = "How long cracks stay on the map.\nkey: duration_crack",
		type   = "number",
		section= 'environment',
		def    = 5,
		min    = 1,
		max    = 100,
		step   = 0.5,
	},
	{
		key    = "comet_rain_radius",
		name   = "Comet rain radius",
		desc   = "Determines the radius of a comet rain.\nkey: comet_rain_radius",
		type   = "number",
		section= 'environment',
		def    = 500,
		min    = 100,
		max    = 100000,
		step   = 100,
	},
	{
		key    = "koth",
		name   = "King of the Hill Mode",
		desc   = "Control the hill for a set amount of time to win! See King of the Hill section.\nkey: koth",
		type   = "bool",
		def    = false,
		section= "kothsection",
	},
	{
		key    = "hilltime",
		name   = "Hill control time",
		desc   = "Set how long a team has to control the hill for (in minutes)\nkey: hilltime",
		type   = "number",
		def    = 3,
		min    = 0.5,
		max    = 15,
		step   = 0.5,
		section= "kothsection",
	},
	{
		key    = "gracetime",
		name   = "No control grace period",
		desc   = "No player can control the hill until period is over (in minutes)\nkey: gracetime",
		type   = "number",
		def    = 0,
		min    = 0,
		max    = 5,
		step   = 0.1,
		section= "kothsection",
	},
	{
		key    = "MetalMult",
		name   = "Metal Extraction Multiplier",
		desc   = "Multiplies metal extraction rate. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "energyMult",
		name   = "Energy Multiplier",
		desc   = "Multiplies energy rate. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "workerMult",
		name   = "BuildSpeed Multiplier",
		desc   = "Multiplies buildspeed. For use in large team games.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "velocityMult",
		name   = "Velocity Multiplier",
		desc   = "Multiplies unitspeed. Use in unison with health..1.3x is similar to BA",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "HitMult",
		name   = "Health Multiplier",
		desc   = "Multiplies unit health. Use in unison with speed.",
		type   = "number",
		def    = 1,
		min    = 0,
		max    = 100,
		step   = 0.05,  -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "multipers",
	},
	{
		key    = "startmetal",
		name   = "Starting metal",
		desc   = "Determines amount of metal and metal storage that each player will start with",
		type   = "number",
		section= "StartingResources",
		def    = 1000,
		min    = 0,
		max    = 10000,
		step   = 1,  -- quantization is aligned to the def value
					-- (step <= 0) means that there is no quantization
	},
	{
		key    = "startenergy",
		name   = "Starting energy",
		desc   = "Determines amount of energy and energy storage that each player will start with",
		type   = "number",
		section= "StartingResources",
		def    = 1000,
		min    = 0,
		max    = 10000,
		step   = 1,  -- quantization is aligned to the def value
					-- (step <= 0) means that there is no quantization
	},

	{
		key  = "enableSlopeMods",
		def  = false,
		type = bool,
		name = "Enable MoveDef slope-modifiers",
		desc = "Determines if ground-units slow down on slopes\nkey: enableSlopeMods",
		section= 'other',
	},
	--Removed till spawner is fixed
	{
		key    = "bosses",
		name   = "Spawn Bosses",
		desc   = "Deadly Powerful Units will come from the depths of space! \nkey: bosses",
		type   = "bool",
		def    = false,
		section= "Fleabowl",
	},
	{
		key    = 'mo_gothtime',
		name   = 'Fleagoth Arrival Time',
		desc   = 'In minutes. Fleagoth will spawn after given time.',
		type   = 'number',
		def    = 60,
		min    = 1,
		max    = 100,
		step   = 1, -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "Fleabowl",
	},
	{
		key    = "mo_maxfleas",
		name   = "Max. Fleas",
		desc   = "Maximum number of fleas on map.",
		type   = "number",
		def    = 1000,
		min    = 50,
		max    = 2000,
		step   = 50,    -- quantization is aligned to the def value
							-- (step <= 0) means that there is no quantization
		section= "Fleabowl",
	},
	{
		key    = "mo_maxburrows",
		name   = "Max. Burrows",
		desc   = "Maximum number of burrows on map.",
		type   = "number",
		def    = 20,
		min    = 1,
		max    = 50,
		step   = 1, -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "Fleabowl",
	},
}

return options
