
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
		
	function gadget:Initialize()	
		gadgetHandler:RegisterGlobal("UnitStoppedMoving", UnitStoppedMoving)
		gadgetHandler:RegisterGlobal("UnitStartedMoving", UnitStartedMoving)
		gadgetHandler:RegisterGlobal("PelicanTransform", PelicanTransform)
		gadgetHandler:RegisterGlobal("PelicanReform", PelicanReform)
	end	
	
	function gadget:ShutDown()
		gadgetHandler:DeregisterGlobal("UnitStoppedMoving", UnitStoppedMoving)
		gadgetHandler:DeregisterGlobal("UnitStartedMoving", UnitStartedMoving)
		gadgetHandler:DeregisterGlobal("PelicanTransform", PelicanTransform)
		gadgetHandler:DeregisterGlobal("PelicanReform", PelicanReform)
	end
	
	function UnitStoppedMoving(unitID,unitDefID,teamID)
		--Echo("Unit landed:",unitID,unitDefID,teamID)
		
		if not airlos[unitDefID] then
			airlos[unitDefID] = Spring.GetUnitSensorRadius(unitID,"airLos")
		end
		--Echo("Airlos:",airlos[unitDefID])
		Spring.SetUnitSensorRadius(unitID,"airLos",min(airlos[unitDefID],50))
		
		if not los[unitDefID] then
			los[unitDefID] = Spring.GetUnitSensorRadius(unitID,"los")
		end
		--Echo("LOS:",los[unitDefID])
		Spring.SetUnitSensorRadius(unitID,"los",min(los[unitDefID],100))
		
	end
	
	function UnitStartedMoving(unitID,unitDefID,teamID)
		--Echo("Unit left land:",unitID,unitDefID,teamID)
		
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
		local success = Spring.MoveCtrl.SetMoveDef(unitID,"kbotsf2")
	end	
else
	return false
end