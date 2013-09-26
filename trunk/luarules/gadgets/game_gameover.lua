function gadget:GetInfo()
  return {
    name      = "Gameover procedure",
    desc      = "Do things related to gameover",
	version   = "1.0",
    author    = "Jools",
    date      = "Sep, 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,  --  loaded by default?
  }
end

local Echo = Spring.Echo
local CMD_FIRE_STATE 		= CMD.FIRE_STATE
local CMD_STOP 				= CMD.STOP

if gadgetHandler:IsSyncedCode() then
	
	-------------------
	-- SYNCED PART --
	-------------------
	
	function gadget:GameOver()
		Spring.PlaySoundFile("sounds/victory1.wav",8.0,0,0,0,0,0,0,'userinterface')
		
		for _, unitID in ipairs(Spring.GetAllUnits()) do
			Spring.SetUnitNeutral(unitID, true)
			Spring.SetUnitNoSelect(unitID, true)
			Spring.GiveOrderToUnit(unitID, CMD_FIRE_STATE, {0}, {})
			Spring.GiveOrderToUnit(unitID, CMD_STOP,{},{})
		end
	
		gadgetHandler:RemoveGadget(self)
		return false
	end
end