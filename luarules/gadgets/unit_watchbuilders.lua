local versionNumber = "1.1"
-- Move/add build commands sound from sounds.tfd


function gadget:GetInfo()
	return {
	name = "WatchBuilders",
	desc = "Set engine to watch land constructors",
	author = "Jools",
	date = "Oct, 2013",
	license = "tango",
	layer = 2,
	enabled = true,
	}
end

-- Shared SYNCED/UNSYNCED
local Echo					= Spring.Echo

if (gadgetHandler:IsSyncedCode()) then

	--SYNCED
	
	-- for some reason T2 are missing
	local watchUnits = {
	arm_construction_kbot = true,
	arm_construction_hovercraft = true,
	arm_construction_ship = true,
	arm_construction_sub = true,
	arm_construction_vehicle = true,
	arm_fark = true,
	core_construction_kbot = true,
	core_construction_hovercraft = true,
	core_construction_ship = true,
	core_construction_sub = true,
	core_construction_vehicle = true,
	core_necro = true,
	lost_construction_kbot = true,
	lost_construction_hovercraft = true,
	lost_construction_ship = true,
	lost_construction_sub = true,
	lost_construction_vehicle = true,
	lost_shaman = true,
	guardian_construction_kbot = true,
	guardian_construction_hovercraft = true,
	guardian_construction_ship = true,
	guardian_construction_sub = true,
	guardian_construction_vehicle = true,
	}
	
	function gadget:Initialize()
		for id, unitDef in ipairs(UnitDefs) do
			
			if watchUnits[unitDef.name] then
				Script.SetWatchUnit(unitDef.id,true)
			end
		end			
	end
	
	
	
	function gadget:Shutdown()
		for id, unitDef in ipairs(UnitDefs) do
			if unitDef.name then
				Script.SetWatchUnit(unitDef.id,false)
			end
		end	
	end	
	
	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID < 0 then
			SendToUnsynced("queuebuildsound", unitTeam,unitID)
		end
		return true
	end
	
	function gadget:UnitMoveFailed(unitID, unitDefID, unitTeam)
		SendToUnsynced("movefailsound", unitTeam,unitID)
	end
	
else
	--UNSYNCED
	
	-----------------
	-- UNSYNCED PART --
	-----------------
	
	local PlaySoundFile				= Spring.PlaySoundFile
	local myTeamID, mySpectatorState
	local GetUnitDefID				= Spring.GetUnitDefID
	local GetConfigInt				= Spring.GetConfigInt
	local GetUnitTeam				= Spring.GetUnitTeam
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("queuebuildsound", QueueBuildSound)
		gadgetHandler:AddSyncAction("movefailsound", MoveFailSound)
		myTeamID = Spring.GetMyTeamID()
		mySpectatorState = Spring.GetSpectatingState()
	end
	
	function QueueBuildSound(_,teamID, unitID)
		local uDefID = CallAsTeam(myTeamID,GetUnitDefID, unitID)
		if teamID == myTeamID and uDefID then
			PlaySoundFile("sounds/gui/button10.wav", 0.5, nil,nil,nil,nil,nil,nil, "userinterface")
		end
	end
		
	function MoveFailSound(_,teamID, unitID)
		if mySpectatorState then return end
		
		local uDefID = CallAsTeam(myTeamID,GetUnitDefID, unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		
		if teamID == myTeamID and uDefID then
			local disableText = (GetConfigInt("XTA_DisableMoveFailedText",0) or 0) == 1 
			local disablesounds = (GetConfigInt("XTA_DisableMoveFailedSound",0) or 0) == 1
			
			if uDefID and (x and y and z) then
				
				if not disableText then
					Echo(UnitDefs[uDefID].humanName .. ": Can't reach destination!")
					Spring.SetLastMessagePosition(x,y,z) 
				end
		
				if not disablesounds then
					PlaySoundFile("sounds/unit/cantdo4.wav", 0.5, x,y,z,0,0,0, "unitreply")
				end
			end
		end	
	end	
end		
