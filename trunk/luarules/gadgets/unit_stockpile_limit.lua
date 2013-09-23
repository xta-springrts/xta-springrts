function gadget:GetInfo()
  return {
    name      = "Stockpile limit",
    desc      = "Prevents units from stockpiling too much ammo",
    author    = "Deadnight Warrior",
    date      = "23 Sep 2013",
    license   = "GNU LGPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local modOptions = Spring.GetModOptions()

-- so far this gadget is only needed for rockettoggle mode due to stockpilable Ravens
function gadget:Initialize()
	if not modOptions or modOptions.rockettoggle=="0" then
		gadgetHandler:RemoveGadget()
	end
end

if gadgetHandler:IsSyncedCode() then

local stockpileLimits = {
	[UnitDefNames["arm_raven_rt"].id] = 40,
}

local spGetUnitStockpile = Spring.GetUnitStockpile
local spSetUnitStockpile = Spring.SetUnitStockpile
local spGiveOrderToUnit = Spring.GiveOrderToUnit

	function gadget:AllowCommand(unitID, unitDefID, unitTeam, cmdID, cmdParams, cmdOptions, cmdTag, synced)
		if cmdID ~= CMD.STOCKPILE then
			return true
		else
			local stock,queued = spGetUnitStockpile(unitID)
			local limit = stockpileLimits[unitDefID]
			if (stock>=limit or queued>limit) and cmdParams[1]~=666 then	
				return false	-- usualy stockpile commands have no params, this way we allow unstockpiling of excess commands
			end
			return true
		end
	end

	function gadget:StockpileChanged(unitID, unitDefID, unitTeam, weaponNum, oldCount, newCount)
		local limit = stockpileLimits[unitDefID]
		if limit then
			if (newCount-oldCount)>0 and oldCount>=limit-1 then
				spSetUnitStockpile(unitID, limit, 0)	-- if a player makes his own widget that circumwents line 37, he'll still hit the limit,
														-- but will waste E until he unstockpiles excess, take that you cheaters
				spGiveOrderToUnit(unitID, CMD.STOCKPILE, {666}, {"right", "ctrl", "shift"})	-- unstockpile excess
				spGiveOrderToUnit(unitID, CMD.STOCKPILE, {666}, {"right", "ctrl", "shift"})
			end
		end
	end

	
	
end