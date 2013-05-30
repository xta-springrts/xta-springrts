gameData = {
	map = "Altair_Crossing_v3",			-- this mission is meant to be played on this map
	game = "XTA",						-- and with this game (short game name)
	minVersion = "$VERSION",				-- and at least this version of game
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
				"CEG dgunflare upperHill 15",
			},
		},				
		{
			conditions = {
				"Always",
			},
			actions = {
				"Bonus arm_commander 0",
			},
			once = true,
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

locations = {	-- use numerical indexes starting from 1 or string names, later preffered
	[1] = {				-- location index or name
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
		X2 = 700,		-- bottom right corner of rectangle
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
	upperHill = {
		shape = "R",
		X1 = 1600,
		Z1 = 1400,
		X2 = 1700,
		Z2 = 1500,
		visible = true,
		RGB = {0.0, 0.4, 0.8},	
	}
}

briefing = {	-- optional, consists of strings which will be displayed one per line
	"$cTest Mission Briefing",
	"",
	"",
	"This is a test mission. It's meant as an example for mission developers to get acquainted with mission editor and",
	"mission script format.",
	"",
	"The objective of this mission is to bring your commander to centre of the map, inside the pulsating red circle.",
	"The two pulsating squares (white and blue) are entrance and exit of a teleport. Moving your units to white square",
	"will teleport them to blue one.",
	"",
	"The briefing text is left aligned and isn't wraped if larger than window. Developer must take care that string line doesn't",
	"exceed line capacity. Nothing serious will happen in that case, it'll only look bad.",
	"If the string begins with $c then that particular line will be centred, $r for right alignment. Formatting command",
	'is ignored in text output and no spaces are needed after it. So you can make a string like: "$cMission Title"',
	"",
	"",
	"$rDeadnight Warrior",
	"$rXTA dev team",
}

return gameData, spawnData, missionTriggers, locations, briefing

--[[	Trigger documentation

All triggers must have conditions and actions arrays, individual conditions and actions are strings.
All conditions and actions must start with a command, and any parameters are separated with spaces.
Command names and parameters are case sensitive.
Only when all conditions of a trigger are true, its actions will happen.
Field "once" can be either set to true, for one-shot trigger, or omitted, for multi-shot triggers.
Locations, switches, timers and variables are referenced by their name.
String parser that pre-parses trigger strings for faster execution accepts any non-space characters,
as spaces are reserved as parameter separators. Though constrain yourself to LUA identifier naming.

Switches, timers and locations can be given a number instead of a name, like:
	locations = {
		upperHill = { ... },
		lowerHill = { ... },
		[1] = { ... },
		[4] = { ... },
	}
but those names may never be strings of digits (even though it's valid from LUA standpoint):
	locations = {
		["1"] = { ... },
		["2"] = { ... },
	}
use regular integer numbers instead, as all numbers in condition and action fields will be parsed to
numbers and never as strings containg digits

Same care should be taken with variables, as "-myVar" is a legal name, it doesn't reffer to negative
value of myVar. If a variable has only digits in its name, it will not be accessible by triggers.
Therefore it's recomended to use at least one letter in variable name.


List of possible conditions:
------------------------------

	Always
unconditional trigger, typically used for initializing values of switches, timers and variables or
displaying messages at start, or some periodical events

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

	Switch (number|name) (true|false)
triggers if the specified switch is set to true or false state, by default switches 1..32
are set to false, others are undefined

	Time quantity
triggers if the game lasts for quantity or longer of seconds

	Timer (number|name)
triggers when the specified timer reaches zero, needs to be set to a value before

	Var name (>|>=|=|<=|<|~=) value
triggers if specified variable is of specified relation compared to value, value can be other variable
just because variables can be used instead of switches for same propose, for performace reasons, avoid it

the quantity values of conditions can be negative, in that case it means less than specified value
if you use a non-numeric value, it will be interpreted as a variable name
examples:	"Res -400 M"			-- triggers if trigger owner has less than 400 metal in pool
			"Ctrl 20 arm_stumpy"	-- triggers if trigger owner has a total of 20 or more Stumpies
			"Ctrl -10 arm_fido 3"	-- triggers if trigger owner has less than 10 Fidos at location 3
			"Kill 5 ANY 4"			-- triggers if trigger owner killed 5 or more units owned by player 4
			"Kill -7 arm_fido"		-- triggers if trigger owner killed less than 7 Fidos in total
			"Var myVar ~= 5"		-- triggers if variable myVar is not equal to 5 
			"Res myVar M"			-- triggers if trigger owner has metal in quantity specified in myVar
									-- or more if value of myVar is negative, then triggers if quantity is
									-- less than abs(myVar)

List of possible actions:
------------------------------

	Bonus (unitname|ANY) minXP [locIdx]
carries over all units of unitname or ANY type with combat experience >= minXP located at location locIdx
or anywhere on the map to next mission, minXP can be a variable

	CEG cegname (x y z dx dy dz r dam|loc h)
spawns a CEG with given name at: given coordiantes, direction, radius and damage
or
at location loc, h above the ground at location center, pointing upward, with radius and damage = 1

	Defeat [teamID]
defeat for player whose trigger this is or specific team

	Echo Any kind of message.
prints a message on the screen, anything after the word "Echo " (space included) till end of string

	Eco quantity (M|E|ME) [teamID]
gives the quantity of resources to player or teamID, quantity can be negative for taking away resources
	
	Give quantity unitname locIdx [teamID]
spawn a quantity of units of unitname type at location locIdx either for player or specified team

	Kill (unitname|ANY) teamID [locIdx]
kills all units of unitname or ANY type owned by teamID, either on entire map or at location locIdx,
units killed this way are counted as killed by trigger owner

	Loc (number|name) (true|false|flip)
sets the visibility of a location specified by number or name to visible (true), invisible (false), or
flips its visibilty state
	
	Move (unitname|ANY) src dest [teamID]
move all units of unitname or ANY type from location src to location dest, owned by either teamID or
every team at location src

	Play soundfile
plays a sound from the game archive, use VFS path, typicaly "sounds/mysound.wav", sound will be global
so in a cooperative mission all players will hear it

	Share (unitname|ANY) teamID [locIdx]
shares all units of unitname or ANY type to teamID, either owned on entire map or at location locIdx,

	Switch (number|name) (true|false|flip)
sets the specified switch to true, false or flips its state, using flip on a undefined switch will
set it to true

	Timer (number|name) quantity
sets the specified countdown timer to quantity of seconds

	Var name (number|name) [operator (number|name)]
if there are 2 parameters, then it sets specified variable to value of second parameter, which can be
another variable, use for (re)initializing a variable
variables are not initialized on game start, use a one-shot unconditional trigger to initialize them
if there are 4 parameters, the specified variable will be set to result of an arithmetical operation
on the second and fourth parameter, which can be either numbers or other variables
possible operators are: + - * / % ^  and they behave exactly as in LUA
variable's name shouldn't contain only digits as it will be parsed as a number not a variable as in LUA

	Victory
victory for ally team to which the trigger owner belongs

	Wait quantity
disables the trigger for quantity of seconds after triggering, this has no effect on
one-shot triggers, all triggers are processed at 1 second intervals

If quantities are non-numeric, they'll be interpreted as variable names
examples:	"Kill ANY 3 2"			-- kills any units controled by player 3 found at location 2
			"Move arm_fido 3 4"		-- moves all Fidos controled by trigger owner from location 3 to location 4
			"Eco -100 M 3"			-- takes away 100 metal from player 3
			"Echo Go for it!"		-- displays "Got for it!" near the bottom of screen (without quotes)
			"Switch 4 flip"			-- inverts the state of switch 4 (true->false or false->true)
			"Share ANY 1"			-- gives all units controled by trigger owner to team 1
			"Share arm_peewee 3 2"	-- gives all PeeWees controled by trigger owner at location 2 to team 3
			"Timer 4 60"			-- sets timer 4 to 60 seconds countdown
			"Play sounds/bang.wav"	-- plays the bang.wav sound located in /sounds/bang.wav, path local to game archive
			"Var myVar 4"			-- sets myVar to 4, needed before first use
			"Var a a + b"			-- a = a + b
			"Var a c ^ 2"			-- a = c ^ 2

-------------------------------
All unknown trigger conditions and unknown actions (command names) will be ignored,
errors in parameters will cause LUA error spam in console

]]
