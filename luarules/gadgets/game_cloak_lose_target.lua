
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
local spGetUnitStealth = Spring.GetUnitStealth
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spIsPosInRadar = Spring.IsPosInRadar
local spIsPosInLos = Spring.IsPosInLos

	function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
		if targetID then
			if spGetUnitIsCloaked(targetID) then
				local x,y,z = spGetUnitPosition(targetID)
				local allyID = spGetUnitAllyTeam(attackerID)
				if spIsPosInRadar(x, y, z, allyID) then
					return true
				else
					return false
					-- TODO: Remove attack order from attackers queue
				end
			--[[  there is Spring.SetUnitStealth, but no Get, unlike with Cloak, which has both Set and Get
			elseif spGetUnitStealth(targetID) then
				local x,y,z = spGetUnitPosition(targetID)
				local allyID = spGetUnitAllyTeam(attackerID)
				if spIsPosInLos(x, y, z, allyID) then
					return true
				else
					return false
					-- TODO: Remove attack order from attackers queue
				end
			--]]
			else
				return true
			end
		end
		return true
	end

end