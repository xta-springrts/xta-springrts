
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
		key  = 'Fleabowl',
		name = 'Fleabowl Stuff',
		desc = 'Use Ai Bots to set Flea difficulty.',
		type = "section",
	},
	{
		key  = "deathmode",
		name = "Game end mode",
		desc = "What it takes to eliminate a team",
		type = "list",
		def  = "killall",
		items = {
			{key="killall", name="Kill Everything *Default works*", desc="Every last unit must be eliminated, no exceptions!"},
		--{key="minors", name="Nothing of value left", desc="The team has no factories and no units left, just defenses and economy"},
			{key="com", name="Kill all enemy Commanders *Could be broken*", desc="When a team has no Commanders left it loses"},
			{key="comcontrol", name="No Commander, No Control *Could be broken*", desc="A player without a Commander cannot issue orders"},
		}
	},
	{
      key="teamdeathmode",
      name="Team Game End Mode",
      desc="What it takes to eliminate a Team",
      type="list",
	  --section= 'xtagame',
      def="allyzerounits",
      items={
         {key="none", name="Never Die", desc="All Teams will stay alive regardless of what happends, gameover will never arrive."},
         {key="teamzerounits", name="Team Death on Zero Units", desc="The Team will die when it has 0 units."},
         {key="allyzerounits", name="AllyTeam Death on Zero units", desc="The Team will die when every Team in his AllyTeam have 0 units."},
      }
   },	{
		key  = "comm",
		name = "Starting Commander",
		desc = "Adjusts Starting Commander type or level",
		type = "list",
		def  = "zeroupgrade",
		items = {
			{ key = "comshooter", name = "Mini Com Shooter Game 0.1", desc = "Play Commander Shooter v0.1" },
			{ key = "decoystart", name = "Start With Decoy", desc = "Start with fake commander" },
			{ key = "capturethebase", name = "Capture the base", desc = "Capture the thing!" },
			{ key = "nincom", name = "Ninja Commanders!", desc = "Micro advised! JOKE START OPTION" },
			{ key = "zeroupgrade", name = "Auto-upgradable Commander", desc = "Automatic upgrades based on commander's experience, default setting" },
			{ key = "noupgrade", name = "Upgradable Level 0 Commander", desc = "Default commander with upgrades available." },
			{ key = "halfupgrade", name = "Upgradable Level 2 Commander", desc = "Powerful lasers are added." },
			{ key = "fullupgrade", name = "Upgradable Level 4 Commander", desc = "Commanders are insanely powerful. (Max upgrade)" }
		},
	},
	{
		key="mo_transportenemy",
		name="Enemy Transporting",
		desc="Toggle which enemy units you can kidnap with a transport vessel",
		type="list",
		def="com",
		section="xtagame",
		items={
			{key="none", name="Allow All", desc="All enemy units can be napped"},
			{key="com", name="All But Commanders", desc="Only commanders are immune to napping"},
			{key="all", name="Disallow All", desc="No enemy units can be napped"},
		}
	},
	{
		key    = "mo_nowrecks",
		name   = "No Unit Wrecks",
		desc   = "Removes all unit wrecks from the game",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "NewUnits",
		name   = "Disable Xta Expansion Pack?",
		desc   = "** Offical ** Disables the newer units that belong in xta versions past 8.1.",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "xtaidUnits",
		name   = 'Enable "XTAids" Unit Pack?',
		desc   = "** ThirdParty ** Adds Xtaids unitpack. Submit your own unitpack or modification! Author: Noruas",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "rockettoggle",
		name   = "Enable togglable rocket type?",
		desc   = "** ThirdParty ** Enable additional rocket type for several rocket/missile units  Author: Deadnight Warrior",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "realscale",
		name   = "Use realistical size and range scale?",
		desc   = "** ThirdParty ** Make all sight, radar, sonar, jammer and weapon ranges and unit max velocities to realistical values. Not recomended on maps smaller than 30x30  Author: Deadnight Warrior",
		type   = "bool",
		def    = false,
		section= "xtagame",
	},
	{
		key    = "nocollide",
		name   = "Projectiles don't collide with friendly units",
		desc   = "** ThirdParty ** Author: Deadnight Warrior",
		type   = "bool",
		def    = false,
		section= "xtagame",
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
		desc   = "Control the hill for a set amount of time to win! See King of the Hill section.",
		type   = "bool",
		def    = false,
		section= "koth",
	},
	{
		key    = "hilltime",
		name   = "Hill control time",
		desc   = "Set how long a team has to control the hill for (in minutes) \nkey: hilltime",
		type   = "number",
		def    = 10,
		min    = 0,
		max    = 60,
		step   = 1.0,
		section= "koth",
	},
	{
		key    = "gracetime",
		name   = "No control grace period",
		desc   = "No player can control the hill until period is over \nkey: gracetime",
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
}

return options
