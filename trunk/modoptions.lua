
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
		key  = 'koth',
		name = 'King of the Hill Settings',
		desc = 'Settings for King of the Hill mode. Add extra boxes then actual teams to declare capture areas, can be more then one extra box.',
		type = "section",
	},
	{
		key  = 'multipers',
		name = 'Multiper Settings',
		desc = 'Settings for multipliers.',
		type = "section",
	},
	
	{
		key  = 'other',
		name = 'Experimental options',
		desc = 'Other non-homologated stuff',
		type = "section",
	},
	
	--[[ Removed till spawner is fixed
	{
		key  = 'Fleabowl',
		name = 'Fleabowl Stuff',
		desc = 'Use Ai Bots to set Flea difficulty.',
		type = "section",
	},
	]]--
	{
		key  = "zombies",
		name = "Zombie Mode",
		desc = "All dead units respawn as hostile neutral zombies!",
		type = "bool",
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
		def="none",
		section="xtagame",
		items={
			{key="none", name="Allow All", desc="All enemy units can be napped"},
			{key="com", name="All But Commanders", desc="Only commanders are immune to napping"},
			{key="all", name="Disallow All", desc="No enemy units can be napped"},
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
		}
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
			
		}
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
		name   = "Disable Xta Expansion Pack?",
		desc   = "** Offical ** Disables the newer units that belong in xta versions past 8.1.\nkey: NewUnits",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "xtaidUnits",
		name   = 'Enable "XTAids" Unit Pack?',
		desc   = "** ThirdParty ** Adds Xtaids unitpack. Submit your own unitpack or modification! Author: Noruas\nkey: xtaidUnits",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "spidertortoise",
		name   = 'Enable "Spiders vs. Tortoise" Unit Pack?',
		desc   = "** ThirdParty ** Adds Spiders and Tortoise unitpack. Originally by TA: Mayhem and TA SECT! Author: Noruas\nkey: spidertortoise",
		type   = "bool",
		def    = false,
		section= "xtagame",
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
		section= 'xtagame',
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
		key		= "globalsounds",
		name	= "Global sounds",
		desc	= "Is sound heard out of player's line of sight? \nkey: globalsounds",
		type	= "bool",
		section	= 'xtagame',
		def		= true,
	},
	
	{
		key		= "debugmode",
		name	= "Debug Mode",
		desc	= "Enable debugging mode. Will allow /cheat by default, and load gadget profiler.\nkey: debugmode",
		type	= "bool",
		section	= 'xtagame',
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
		key    = "kingofthehill",
		name   = "King of the Hill Mode",
		desc   = "Control the hill for a set amount of time to win! See King of the Hill section.\nkey: kingofthehill",
		type   = "bool",
		def    = false,
		section= "koth",
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
		section= "koth",
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
		section= "koth",
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
	},
	--[[ Removed till spawner is fixed
	{
		key    = "BOSSES",
		name   = "Spawn Bosses",
		desc   = "Deadly Powerful Units will come from the depths of space! \nkey: BOSSES",
		type   = "bool",
		def    = false,
		section= "Fleabowl",
	},
	{
		key    = 'mo_queentime',
		name   = 'Queen Arrival Time',
		desc   = 'In minutes. Queen will spawn after given time.',
		type   = 'number',
		def    = 60,
		min    = 1,
		max    = 100,
		step   = 1, -- quantization is aligned to the def value
						-- (step <= 0) means that there is no quantization
		section= "Fleabowl",
	},
	{
		key    = "mo_maxchicken",
		name   = "Max. Chickens",
		desc   = "Maximum number of chickens on map.",
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
	]]--
}

return options
