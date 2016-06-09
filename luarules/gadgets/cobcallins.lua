
function gadget:GetInfo()
  return {
    name      = "Cobcallins",
    desc      = "Calls functions from unit scripts",
	version   = "1.0",
    author    = "Jools",
    date      = "Mar, 2014",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

if gadgetHandler:IsSyncedCode() then
	-----------------
	-- SYNCED PART --
	-----------------
	
	local Echo 				= Spring.Echo
	local airlos			= {}
	local los				= {}
	local max				= math.max
	local min				= math.min
	local GiveOrderToUnit 	= Spring.GiveOrderToUnit
	local CMD_WAIT			= CMD.WAIT
	
	local gunships		= {}
	local spring101 = (Game.version > "100" and Game.version:sub(1,1) == "1")
		
	function gadget:Initialize()	
		gadgetHandler:RegisterGlobal("UnitStoppedMoving", UnitStoppedMoving)
		gadgetHandler:RegisterGlobal("UnitStartedMoving", UnitStartedMoving)
		gadgetHandler:RegisterGlobal("UnitActivated", UnitActivated)
		gadgetHandler:RegisterGlobal("UnitDeactivated", UnitDeactivated)
		gadgetHandler:RegisterGlobal("PelicanTransform", PelicanTransform)
		gadgetHandler:RegisterGlobal("PelicanReform", PelicanReform)
		
		for id,unitDef in pairs(UnitDefs) do
			if unitDef.hoverAttack then				
				gunships[id] = true
			end
		end
		
	end	
	
	function gadget:Shutdown()
		gadgetHandler:DeregisterGlobal("UnitActivated")
		gadgetHandler:DeregisterGlobal("UnitDeactivated")
		gadgetHandler:DeregisterGlobal("UnitStoppedMoving")
		gadgetHandler:DeregisterGlobal("UnitStartedMoving")
		gadgetHandler:DeregisterGlobal("PelicanTransform")
		gadgetHandler:DeregisterGlobal("PelicanReform")
	end
	
	-- temporary fix for spring 100 and before
	-- https://springrts.com/mantis/view.php?id=5080
	if not spring101 then
		function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
			if UnitDefs[unitDefID].canFly then
				if cmdID == CMD.GUARD or cmdID == CMD.AREAGUARD then
					Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, { 0 }, { })  -- set to fly
				elseif cmdID == CMD.STOP then
					Spring.GiveOrderToUnit(unitID, CMD.IDLEMODE, { 1 }, { })  -- set to land
				end
			end
			return true
		end
	end
	
	function UnitActivated(unitID,unitDefID,teamID)
		--Echo("Activated() called for unitID:",unitID,UnitDefs[unitDefID].name)
	end
	
	function UnitDeactivated(unitID,unitDefID,teamID)
		--Echo("Deactivated() called for unitID:",unitID,UnitDefs[unitDefID].name)
	end
	
	-- only applies for units that call lua_UnitStoppedMoving() in cob
	function UnitStoppedMoving(unitID,unitDefID,teamID)
		--Echo("StoppedMoving() called for unitID:",unitID,UnitDefs[unitDefID].name)
				
		if not airlos[unitDefID] then
			local this_airlos = Spring.GetUnitSensorRadius(unitID,"airLos")
			if this_airlos and this_airlos > 0 then
				airlos[unitDefID] = this_airlos
			end
		end
		
		if gunships[unitDefID] then
			Spring.SetUnitSensorRadius(unitID,"airLos",min(airlos[unitDefID] or 400,400))
		else
			Spring.SetUnitSensorRadius(unitID,"airLos",min(airlos[unitDefID] or 50,50))
		end
		if not los[unitDefID] then
			local this_los = Spring.GetUnitSensorRadius(unitID,"los")
			if this_los and this_los > 0 then
				los[unitDefID] = this_los
			end
		end
		
		if gunships[unitDefID] then
			Spring.SetUnitSensorRadius(unitID,"los",min(los[unitDefID] or 300,300))
		else
			Spring.SetUnitSensorRadius(unitID,"los",min(los[unitDefID] or 100,100))
			SendToUnsynced("VTOLStoppedMoving", unitID,unitDefID)
		end
	end
	
	function UnitStartedMoving(unitID,unitDefID,teamID)
		--Echo("StartMoving() called for unitID:",unitID,UnitDefs[unitDefID].name)
		if airlos[unitDefID] then 
			Spring.SetUnitSensorRadius(unitID,"airLos",airlos[unitDefID])
		end
		
		if los[unitDefID] then 
			Spring.SetUnitSensorRadius(unitID,"los",los[unitDefID])
		end
	end
	
	function PelicanTransform(unitID,unitDefID,teamID)
		local success = Spring.MoveCtrl.SetMoveDef(unitID,"hover2")
		GiveOrderToUnit(unitID, CMD_WAIT, {}, {}) -- hack to prevent pelicans from getting stuck bc of pathfinder
		GiveOrderToUnit(unitID, CMD_WAIT, {}, {})
	end
	
	function PelicanReform(unitID,unitDefID,teamID)
		local success = Spring.MoveCtrl.SetMoveDef(unitID,"KBOTUW3")
	end	
else

-----------------
	-- UNSYNCED PART --
	-----------------
	
	local PlaySoundFile				= Spring.PlaySoundFile
	local Echo 						= Spring.Echo
	local GetConfigInt				= Spring.GetConfigInt
	local GetUnitTeam				= Spring.GetUnitTeam
	function gadget:Initialize()
		gadgetHandler:AddSyncAction("VTOLStoppedMoving", VTOLStoppedMoving)
		myTeamID = Spring.GetMyTeamID()
	end
	
	function VTOLStoppedMoving(_,unitID, unitDefID )
		
		local teamID = GetUnitTeam(unitID)
		if teamID and teamID == myTeamID then
			local ud = UnitDefs[unitDefID]
			if ud and not ud.sounds.arrived[1] then
				Echo("Error: no arrived sound for:",ud.name)
			end
			local sound = ud and ud.sounds.arrived and ud.sounds.arrived[1] and ud.sounds.arrived[1].name
			if sound then
				--Echo("USM:",unitID,sound)
				PlaySoundFile("sounds/"..sound ..".wav", 0.25, nil,nil,nil,nil,nil,nil, "unitreply")
			end
		end
	end
	
end