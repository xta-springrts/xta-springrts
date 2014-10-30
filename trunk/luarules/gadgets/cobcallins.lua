
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
	
	local Echo 			= Spring.Echo
	local airlos		= {}
	local los			= {}
	local max			= math.max
	local min			= math.min
	
	local gunships		= {}
		
	function gadget:Initialize()	
		gadgetHandler:RegisterGlobal("UnitStoppedMoving", UnitStoppedMoving)
		gadgetHandler:RegisterGlobal("UnitStartedMoving", UnitStartedMoving)
		gadgetHandler:RegisterGlobal("PelicanTransform", PelicanTransform)
		gadgetHandler:RegisterGlobal("PelicanReform", PelicanReform)
		
		for id,unitDef in pairs(UnitDefs) do
			if unitDef.hoverAttack then				
				gunships[id] = true
			end
		end
		
	end	
	
	function gadget:Shutdown()
		gadgetHandler:DeregisterGlobal("UnitStoppedMoving", UnitStoppedMoving)
		gadgetHandler:DeregisterGlobal("UnitStartedMoving", UnitStartedMoving)
		gadgetHandler:DeregisterGlobal("PelicanTransform", PelicanTransform)
		gadgetHandler:DeregisterGlobal("PelicanReform", PelicanReform)
	end
	
	function UnitStoppedMoving(unitID,unitDefID,teamID)
		
		if not airlos[unitDefID] then
			airlos[unitDefID] = Spring.GetUnitSensorRadius(unitID,"airLos")
		end
		
		if gunships[unitDefID] then
			Spring.SetUnitSensorRadius(unitID,"airLos",min(airlos[unitDefID],400))
		else
			Spring.SetUnitSensorRadius(unitID,"airLos",min(airlos[unitDefID],50))
		end
		if not los[unitDefID] then
			los[unitDefID] = Spring.GetUnitSensorRadius(unitID,"los")
		end
		
		if gunships[unitDefID] then
			Spring.SetUnitSensorRadius(unitID,"los",min(los[unitDefID],300))
		else
			Spring.SetUnitSensorRadius(unitID,"los",min(los[unitDefID],100))
		end
	end
	
	function UnitStartedMoving(unitID,unitDefID,teamID)
		
		if airlos[unitDefID] then 
			Spring.SetUnitSensorRadius(unitID,"airLos",airlos[unitDefID])
		end
		
		if los[unitDefID] then 
			Spring.SetUnitSensorRadius(unitID,"los",los[unitDefID])
		end	
	end
	
	function PelicanTransform(unitID,unitDefID,teamID)
		local success = Spring.MoveCtrl.SetMoveDef(unitID,"hover2")
	end
	
	function PelicanReform(unitID,unitDefID,teamID)
		local success = Spring.MoveCtrl.SetMoveDef(unitID,"KBOTUW3")
	end	
else
	return false
end