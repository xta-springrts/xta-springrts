gameData = {
	map = "Altair_Crossing_v3",			-- this mission is meant to be played on this map
	game = "XTA",						-- and with this game (short game name)
	minVersion = "9 SVN",				-- and at least this version of game
	nextMission = "XTA_tutorial_mission",	-- next mission after victory, optional
}

spawnData = {
	teams = {		-- list of teams and their starting units and buildings
		[0] = {		-- [teamID]
			{"arm_commander", 460, 924, 1},	-- {"unitname", X, Z, worldside (0=south, 1=east, 2=north, 3=west)}
			{"arm_energy_storage", 420, 800, 0},
		},
		[1] = {
			{"core_commander", 3760, 2018, 3},
			{"core_energy_storage", 3820, 2400, 0}
		},
	},
	features = {					-- list of features to spawn on map at game start
		{"arm_bulldog_dead", 1200, 800, 16384, 0}, -- {"featurename", X, Z, heading (0..64K), ownerID}
	}
}

missionTriggers = {
	[0] = {	-- teamID this trigger applies to, teamIDs are 0..N-1, where N is the number of teams
		{-- list of triggers
			conditions = {	-- if all conditions are true, actions will happen
				"Always",
			},
			actions = {
				"Echo Bring your commander to the center of the map",
				"Wait 11",	-- this will disable the trigger for 11 seconds after triggering
			},
		},
		{
			conditions = {
				"Always",
			},
			actions = {
				"Give 14 arm_peewee 2",
			},
			once = true,	-- this will trigger only once
		},
		{
			conditions = {		-- teleporter
				"Ctrl 1 ANY 3",
			},
			actions = {
				"Move ANY 3 2",
			},
		},
		{	
			conditions = {
				"Ctrl 1 arm_commander 1",
			},
			actions = {
				"Echo Yay, you did it!",
				"Victory",
			},
			once = true,
		},
		{	
			conditions = {
				"Kill 5 core_ak 1",
			},
			actions = {
				"Echo Yay, killed 5 AKs!",
			},
			once = true,
		},	
		{	
			conditions = {
				"Kill 10 core_ak",
			},
			actions = {
				"Echo Yay, killed 10 AKs!",
			},
			once = true,
		},	
	},
	[1] = {
		{
			conditions = {
				"Death 5 core_ak"
			},
			actions = {
				"Echo Enemy lost 5 AKs"
			},
			once = true,
		},
		{
			conditions = {
				"Death 12 ANY"
			},
			actions = {
				"Echo Enemy lost 12 units"
			},
			once = true,
		}
	},
}

locations = {	-- use numerical indexes starting from 1
	[1] = {				-- location index
		shape = "C",	-- circle
		X = 2048,		-- center (yes, it's capital letters for coordinates)
		Z = 2048,
		r = 60,			-- radius
		visible = true,	-- drawn on the ground or not, set to false or omit for invisible
		RGB = {1.0, 0.0, 0.0},	-- draw the location with this colour, if omitted uses white
	},
	[2] = {
		shape = "R",	-- rectangle
		X1 = 600,		-- top left corner of rectangle
		Z1 = 900,
		X2 = 700,		--bottom right corner of rectangle
		Z2 = 1000,
		visible = true,
		RGB = {0.0, 0.0, 0.8},
	},
	[3] = {
		shape = "R",
		X1 = 600,
		Z1 = 200,
		X2 = 700,
		Z2 = 300,
		visible = true,
	},
}

return gameData, spawnData, missionTriggers, locations

--[[	Trigger documentation

All triggers must have conditions and actions arrays, individual conditions and actions are strings
All conditions and actions must start with a command, and any parameters are separated with spaces
Command names and parameters are case sensitive
Only when all conditions of a trigger are true, its actions will happen
Field "once" can be either set to true, for one-shot trigger, or omitted, for multi-shot triggers
All locations are referenced by their index number in the locations table, and all teams are
referenced by their teamID number

List of possible conditions:
------------------------------

	Always
unconditional trigger

	Ctrl quantity (unitname|ANY) [locIdx]
triggers when the player commands over quantity or more units of unitname or ANY type
either on entire map or at location specified in locations list at index locIdx

	Death quantity (unitname|ANY) [ownerID]
triggers when the specified team or trigger owner suffers death of quantity or more of
the unitname or ANY type of unit 

	Kill quantity (unitname|ANY) [ownerID]
triggers when the player kills quantity or more units of unitname or ANY type, limited or not
by owner (Gaia team excluded) of the killed units

	Res quantity (M|E|ME) [teamID]
triggers if the specified team or trigger owner have quantity of resource[s] or more in pool

	Switch number (true|false)
triggers if the specified switch is set to true or false state, by default switches 1..32
are set to false, if you use more, define them before using "flip" action on a switch

	Time quantity
triggers if the game lasts for quantity or longer of seconds

	Timer number
triggers when the specified timer reaches zero, needs to be set to a value before

the quantity values of conditions can be negative, in that case it means less than specified value
examples:	"Res -400 M"			-- triggers if player has less than 400 metal in pool
			"Ctrl 20 arm_stumpy"	-- triggers if player has a total of 20 or more Stumpies
			"Ctrl -10 arm_fido 3"	-- triggers if player has less than 10 Fidos at location 3
			"Kill 5 ANY 4"			-- triggers if player killed 5 or more units owned by player 4
			"Kill -7 arm_fido"		-- triggers if player killed less than 7 Fidos in total

List of possible actions:
------------------------------

	Defeat [teamID]
defeat for player whose trigger this is or specific team

	Echo Any kind of message.
prints a message on the screen, anything after the word Echo till end of string

	Eco quantity (M|E|ME) [teamID]
gives the quantity of resources to player or teamID, quantity can be negative for taking away resources
	
	Give quantity unitname locIdx [teamID]
spawn a quantity of units of unitname type at location locIdx either for player or specified team

	Kill (unitname|ANY) teamID [locIdx]
kills all units of unitname or ANY type for teamID, either on entire map or at location locIdx,
units killed this way are counted as killed by trigger owner

	Move (unitname|ANY) src dest [teamID]
move all units of unitname or ANY type from location src to location dest, filtered by
either teamID or all units at location src

	Play soundfile
plays a sound from the game archive, use VFS path, typicaly "sounds/mysound.wav", sound will be global
so in a cooperative mission all player will hear it

	Share (unitname|ANY) teamID [locIdx]
shares all units of unitname or ANY type to teamID, either owned on entire map or at location locIdx,

	Switch number (true|false|flip)
sets the switch specified by number to true, false or flips its state

	Timer number quantity
sets the countdown timer specified by number to quantity of seconds

	Victory
victory for ally team to which the player belongs whose trigger this is

	Wait quantity
disables the trigger for quantity of seconds after triggering, this has no effect on
one-shot triggers, all triggers are processed at 1 second intervals

examples:	"Kill ANY 3 2"			-- kills any units controled by player 3 found at location 2
			"Move arm_fido 3 4"		-- moves all Fidos controled by trigger owner from location 3 to location 4
			"Eco -100 M 3"			-- takes away 100 metal from player 3
			"Echo Go for it!"		-- types "Got for it!" in the chat console (without quotes)
			"Switch 4 flip"			-- inverts the state of switch 4 (true->false or false->true)
			"Share ANY 1"			-- gives all units controled by trigger owner to team 1
			"Share arm_peewee 3 2"	-- gives all PeeWees controled by trigger owner at location 2 to team 3
			"Timer 4 60"			-- sets timer 4 to 60 seconds countdown
			"Play sounds/bang.wav"	-- plays the bang.wav sound located in /sounds/bang.wav, path local to game archive

-------------------------------
All unknown trigger conditions and unknown actions (command names) will be ignored,
errors in parameters will cause LUA error spam in console

]]
