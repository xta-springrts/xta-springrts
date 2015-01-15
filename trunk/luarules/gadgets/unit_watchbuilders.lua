local versionNumber = "1.0"

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
	
	function gadget:UnitMoveFailed(unitID, unitDefID, unitTeam)
		SendToUnsynced("movefailsound", unitTeam,unitID)
	end
	
else
	--UNSYNCED
	
	-----------------
	-- UNSYNCED PART --
	-----------------
	
	local PlaySoundFile				= Spring.PlaySoundFile
	local failed					= "sounds/cantdo4.wav"
	local myTeamID, mySpectatorState
	local GetUnitDefID				= Spring.GetUnitDefID
	
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("movefailsound", MoveFailSound)
		myTeamID = Spring.GetMyTeamID()
		mySpectatorState = Spring.GetSpectatingState()
	end

	function MoveFailSound(_,teamID, unitID)
		if mySpectatorState then return end
		
		local uDefID = CallAsTeam(myTeamID,GetUnitDefID, unitID)
		local x,y,z = Spring.GetUnitPosition(unitID)
		
		if teamID == myTeamID and uDefID then
			local disableText = (Spring.GetConfigInt("DisableMoveFailedText",0) or 0) == 1 
			local disablesounds = (Spring.GetConfigInt("DisableMoveFailedSound",0) or 0) == 1
		
			if uDefID and (x and y and z) then
				
				if not disableText then
					Echo(UnitDefs[uDefID].humanName .. ": Can't reach destination!")
					Spring.SetLastMessagePosition(x,y,z) 
				end
		
				if not disablesounds then
					Spring.PlaySoundFile("sounds/cantdo4.wav", 1.0, nil, "ui")
				end
			end
		end	
	end	
end		
