
function gadget:GetInfo()
  return {
    name      = "Cloak lose target",
    desc      = "Prevents units from continuing of attacking cloaked units if no radar coverage, same for stealth outside LoS.",
    author    = "Deadnight Warrior",
    date      = "19 Feb 2013",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if gadgetHandler:IsSyncedCode() then

local spGetUnitIsCloaked = Spring.GetUnitIsCloaked
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spIsPosInRadar = Spring.IsPosInRadar
local spIsPosInLos = Spring.IsPosInLos

	function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
		if targetID then
			local x,y,z = spGetUnitPosition(targetID)
			local allyID = spGetUnitAllyTeam(attackerID)
			if spGetUnitIsCloaked(targetID) then
				return spIsPosInRadar(x, y, z, allyID), defaultPriority
				-- TODO: Remove attack order from attackers queue
			else
				if spIsPosInLos(x, y, z, allyID) then
					return true, defaultPriority
				else
					return spIsPosInRadar(x, y, z, allyID), defaultPriority
					-- TODO: Remove attack order from attackers queue
				end
			end
		end
		return true, defaultPriority
	end

end