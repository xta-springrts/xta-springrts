gameData = {
	map = "Altair_Crossing_v3",			-- this mission is ment to be played on this map
	game = "XTA",						-- and with this game (short game name)
	minVersion = "9 SVN",				-- and at least this version of game
	nextMission = "XTA_tutorial_mission",	-- next mission after victory, optional
}

spawnData = {
	teams = {		--list of teams and their starting units and buildings
		[0] = {		--teamdID
			{"arm_commander", 460, 924, 1},	--{"unitname", X, Z, worldside (0=south, 1=east, 2=north, 3=west)}
			{"arm_energy_storage", 420, 800, 0},
		},
		[1] = {
			{"core_commander", 3760, 2018, 3},
			{"core_energy_storage", 3820, 2400, 0}
		},
	},
	features = {					--list of features to spawn on map at game start
		{"arm_bulldog_dead", 1200, 800, 16384, 0}, --{"featurename", X, Z, heading (0..64K), ownerID}
	}
}

missionTriggers = {
	[0] = {	--playerID this trigger applies to
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
			once = true,
		},
		{	
			conditions = {
				"Ctrl 1 arm_commander 1",
			},
			actions = {
				"Echo Yay, you did it!",
				"Victory",
			},
			once = true,	-- this will trigger only once
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
		X = 2048,		-- center
		Z = 2048,
		r = 60,			-- radius
		visible = true,	-- drawn on the ground or not (not currently implemented)
	},
	[2] = {
		shape = "R",	-- rectangle
		X1 = 600,		-- top left corner of rectangle
		Z1 = 900,
		X2 = 700,		--bottom right corner of rectangle
		Z2 = 1000,
		visible = false,
	},
}

return gameData, spawnData, missionTriggers, locations

--[[	Trigger documentation

All triggers must have conditions and actions arrays, individual conditions and actions are strings
Field once can be either set to true, for one-shot trigger, or ommited, for multi-shot triggers
Only when all conditions of a trigger are true, it's actions will happen

List of possible conditions:
------------------------------

	Always
unconditional trigger

	Ctrl quantity (unitname|ANY) [index]
triggers when the player commands over quantity or more units of unitname or ANY type
either on entire map or at location specified in locations list at index

	Death quantity (unitname|ANY) [ownerID]
triggers when the specified team or trigger owner suffers death of quantity or more of
the unitname or ANY type of unit 

	Kill quantity (unitname|ANY) [ownerID]
triggers when the player kills quantity or more units of unitname or ANY type, limited or not
by owner (Gaia team excluded) of the killed units

	Res quantity (M|E|ME)
triggers if player has quantity of resource[s] or more in pool

	Switch number (true|false)
triggers if the switch of number is set to true or false state, by default switches 1..32
are set to false, if you use more, define them before using "flip" action on a switch,
use "Always" condition and as many "Switch n (true|false)" actions as needed, make the
trigger one-shot

	Time quantity
triggers if the game lasts for quantity or longer of seconds 

the quantity values of conditions can be negative, in that case it means less than specified value
example:	"Res -400 M"			-- triggers if player has less than 400 metal in pool
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
	
	Give quantity unitname index [teamID]
spawn a quantity of units of unitname type at location specified in locations list at index
either for player or specified team

	Kill (unitname|ANY) teamID [index]
kills all units of unitname or ANY type for teamID, either on entire map or at location
specified in locations list at index, units killed this way are counted as killed by trigger owner

	Move (unitname|ANY) src dest [teamID]		-- not currently implemented
move all units of unitname or ANY type from location specified in locations list at src to
location dest filtered by either teamID or for all units at location index

	Switch number (true|false|flip)
sets the switch of number to true, false or flips its state

	Victory
victory for ally team to which the player belongs whose trigger this is

	Wait quantity
disables the trigger for quantity of seconds after triggering, this has no effect on
one-shot triggers, all triggers are processed at 1 second intervals

-------------------------------
All unknown trigger conditions and unknown actions (command names) will be ignored,
errors in parameters will cause LUA error spam in console

]]