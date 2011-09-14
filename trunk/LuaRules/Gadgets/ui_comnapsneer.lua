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

local snd = 'sounds/sneer_mono.ogg'



if (gadgetHandler:IsSyncedCode()) then
	function gadget:Initialize()
	 -- if Spring.GetSpectatingState() or Spring.IsReplay() then
		 -- gadgetHandler:RemoveGadget()
		 -- return true
	 -- end	
	end

	function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
		if not Spring.AreTeamsAllied (unitTeam, transportTeam) and UnitDefs[unitDefID].isCommander then
			Spring.PlaySoundFile(snd)
			--Spring.Echo("A commander is napped!")
		end
	end
end