
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
	
	
	-- NOTE: disables units keeping target on cloaked units and also units outside of LOS, for example bombers that
	-- have attack order on a target that disappers. But the non-cloaking part is disabled because it is heavy on
	-- performance, see http://springrts.com/mantis/view.php?id=4568
	-- For every unit it checks LOS, and this can be heavy e.g. if there are 100 stumpies fighting each other.
	-- Maybe second part should only apply for air units?
	
	function gadget:AllowWeaponTarget(attackerID, targetID, attackerWeaponNum, attackerWeaponDefID, defaultPriority)
		if targetID then
			if spGetUnitIsCloaked(targetID) then
				local x,y,z = spGetUnitPosition(targetID)
				local allyID = spGetUnitAllyTeam(attackerID)
				return spIsPosInRadar(x, y, z, allyID), defaultPriority
				-- TODO: Remove attack order from attackers queue
			--else -- disabled because of bad performance
				--if spIsPosInLos(x, y, z, allyID) then
					--return true, defaultPriority
				--else
					--return spIsPosInRadar(x, y, z, allyID), defaultPriority
					-- TODO: Remove attack order from attackers queue
				--end
			end
		end
		return true, defaultPriority
	end

end