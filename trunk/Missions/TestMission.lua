spawnData = {
	map = "Altair_Crossing_v3",		--this mission is ment to be played on this map
	teams = {						--list of teams and their starting units and buildings
		[0] = {		--teamdID
			{"arm_commander", 460, 924, 1},	--{"unitname", X, Z, worldside (0=south, 1=east, 2=north, 3=west)}
			{"arm_energy_storage", 420, 800, 0},
		},
		[1] = {
			{"core_commander", 3760, 2018, 3},
			{"core_energy_storage", 3820, 2400, 0}
		},
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
				"Wait 10",	--this will disable the trigger for 10 seconds after triggering
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
			once = true,	--this will trigger only once
		},
		{	
			conditions = {
				"Kill 5 core_ak 1",
			},
			actions = {
				"Echo Yay, killed 5 AKs!",
			},
			once = true,	--this will trigger only once
		},	
		{	
			conditions = {
				"Kill 10 core_ak",
			},
			actions = {
				"Echo Yay, killed 10 AKs!",
			},
			once = true,	--this will trigger only once
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

locations = {	--use numerical indexes starting from 1
	[1] = {				--location index
		shape = "C",	--circle
		X = 2048,		--center
		Z = 2048,
		r = 60,			--radius
		visible = true,	--drawn on the ground or not
	},
	[2] = {
		shape = "R",	--rectangle
		X1 = 600,		--top left corner of rectangle
		Z1 = 900,
		X2 = 700,		--bottom right corner of rectangle
		Z2 = 1000,
		visible = false,
	},
}

return spawnData, missionTriggers, locations

--[[	Trigger documentation

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
by owner of the killed units, Gaia team excluded

	Res quantity (M|E|ME)
triggers if player has quantity of resource[s] or more in pool

	Switch number (true|false)
triggers if the switch of number is set to true or false state, by default switches 1..32
are set to false, if you use more, define them before using "flip" action on a switch

the quantity values can be negative, in that case it means less than specified value
example:	Res -400 M				--triggers if player has less than 400 metal in pool
			Ctrl 20 arm_stumpy		--triggers if player has a total of 20 or more Stumpies
			Ctrl -10 arm_fido 3		--triggers if player has less than 10 Fidos at location 3

List of possible actions:
------------------------------

	Defeat
defeat for player whose trigger this is

	Echo Any kind of message.
prints a message on the (true|false)screen, anything after the word Echo till end of string

	Eco quantity (M|E|ME) [teamID]
gives the quantity of resources to player or teamID, quantity can be negative for taking away resources
	
	Give quantity unitname index [teamID]		--not currently implemented
spawn a quantity of units of unitname type at location specified in locations list at index
either for player or specified team

	Kill (unitname|ANY) teamID [index]
kills all units of unitname or ANY type for teamID, either on entire map or at location
specified in locations list at index, units killed this way are counted as killed by trigger owner

	Move (unitname|ANY) src dest [teamID]		--not currently implemented
move all units of unitname or ANY type from location specified in locations list at src to
location dest filtered by either teamID or for all units at location index

	Switch number (true|false|flip)
sets the switch of number to true, false or flips its state

	Victory
victory for ally team to which the player belongs whose trigger this is

	Wait time
disables the trigger for time seconds after triggering, this has no effect on
one time triggers, all triggers are processed at 1 second intervals

-------------------------------
All unknown trigger conditions and unknown actions will be ignored

]]