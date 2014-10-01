function gadget:GetInfo()
	return {
	name = "Sneer after comnap",
	desc = "Play a humiliating tune at comnap",
	author = "Jools",
	date = "July, 12, 2011",
	license = "sea lion",
	layer = 1,
	enabled = true
	}
end

-- 2014.10: Updated to load commandertable and localised some vars

if (gadgetHandler:IsSyncedCode()) then
	
	local snd = 'sounds/sneer_mono.ogg'
	local commanderTable = include("LuaRules/Configs/unit_commander_sounds_defs.lua")
	local AreTeamsAllied = Spring.AreTeamsAllied

	function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		if not AreTeamsAllied (unitTeam, transportTeam) and commanderTable[unitDefID] then
			Spring.PlaySoundFile(snd)
		end
	end
end